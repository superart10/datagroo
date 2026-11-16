import asyncio
import logging
from datetime import date, timedelta

from fastapi import APIRouter, HTTPException, Query, status

from app.config import POWER_RETRASO_DIAS
from app.logica.clima import resumir
from app.modelos.parcela import ClimaCoordenadasRespuesta, ClimaRespuesta, Coordenadas
from app.servicios import db, earthdata, nasa_gpm, nasa_power, smap

registro = logging.getLogger("uvicorn.error")

router = APIRouter(prefix="/parcelas", tags=["Clima"])

# Rutas que no dependen de una parcela guardada en el servidor: el frontend
# guarda sus terrenos en SQLite local y solo manda las coordenadas.
router_coordenadas = APIRouter(tags=["Clima"])


def _parcela_o_404(parcela_id: int) -> dict:
    parcela = db.obtener_parcela(parcela_id)
    if parcela is None:
        raise HTTPException(status_code=404, detail="Parcela no encontrada")
    return parcela


def _respuesta(parcela_id: int, dias: list[dict]) -> dict:
    return {
        "parcela_id": parcela_id,
        "inicio": dias[0]["fecha"] if dias else None,
        "fin": dias[-1]["fecha"] if dias else None,
        "resumen": resumir(dias),
        "dias": dias,
    }


def _periodo(dias: int) -> tuple[date, date]:
    fin = date.today() - timedelta(days=POWER_RETRASO_DIAS)
    return fin - timedelta(days=dias - 1), fin


async def _consultar_power(lat: float, lon: float, dias: int) -> list[dict]:
    inicio, fin = _periodo(dias)
    try:
        return await nasa_power.consultar_clima(lat, lon, inicio, fin)
    except nasa_power.ErrorPower as e:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(e))


@router_coordenadas.post(
    "/clima",
    response_model=ClimaCoordenadasRespuesta,
    response_model_exclude_none=True,
)
async def clima_por_coordenadas(
    coordenadas: Coordenadas, dias: int = Query(7, ge=1, le=31)
):
    """Recibe `{"latitude", "longitude"}` y responde con las claves que lee la
    app Flutter: `temperature` (°C), `precipitation` (mm/día) y `soil_moisture` (%).

    Fuentes: temperatura de NASA POWER, lluvia de GPM y humedad del suelo de
    SMAP. Si GPM o SMAP no responden (o falta el token de Earthdata), ese valor
    se toma de NASA POWER; `precipitation_source` y `soil_moisture_source` dicen
    de dónde salió cada uno.

    Un valor sin datos se omite de la respuesta (nunca va como null), porque el
    frontend solo comprueba si la clave existe antes de convertirla a número.
    """
    lat, lon = coordenadas.latitude, coordenadas.longitude
    inicio, fin = _periodo(dias)

    # Las tres fuentes se consultan a la vez.
    datos, lluvia_gpm, humedad_smap = await asyncio.gather(
        _consultar_power(lat, lon, dias),
        _o_nada(nasa_gpm.consultar_lluvia(lat, lon, inicio, fin), nasa_gpm.FUENTE),
        _o_nada(smap.consultar_humedad(lat, lon, inicio, fin), smap.FUENTE),
    )

    lluvia, fuente_lluvia = _promedio(lluvia_gpm, "precipitacion_mm"), nasa_gpm.FUENTE
    if lluvia is None:
        lluvia, fuente_lluvia = _promedio(datos, "precipitacion_mm"), nasa_power.FUENTE

    humedad, fuente_humedad = _promedio(humedad_smap, "humedad_suelo"), smap.FUENTE
    if humedad is None:
        humedad, fuente_humedad = _promedio(datos, "humedad_suelo"), nasa_power.FUENTE

    return {
        "latitude": lat,
        "longitude": lon,
        "temperature": resumir(datos)["temp_media_c"],
        "precipitation": round(lluvia, 2) if lluvia is not None else None,
        # Las dos fuentes entregan la humedad como fracción 0-1; el frontend la usa en %.
        "soil_moisture": round(humedad * 100, 1) if humedad is not None else None,
        "precipitation_source": fuente_lluvia if lluvia is not None else None,
        "soil_moisture_source": fuente_humedad if humedad is not None else None,
        "start": datos[0]["fecha"] if datos else None,
        "end": datos[-1]["fecha"] if datos else None,
    }


async def _o_nada(consulta, fuente: str) -> list[dict]:
    """Ejecuta una consulta a Earthdata; si falla, avisa en la consola y devuelve
    una lista vacía para que el valor se tome de NASA POWER."""
    if not earthdata.hay_token():
        consulta.close()
        return []
    try:
        return await consulta
    except earthdata.ErrorEarthdata as e:
        registro.warning("%s no disponible, se usa NASA POWER: %s", fuente, e)
        return []


def _promedio(dias: list[dict], campo: str) -> float | None:
    valores = [d[campo] for d in dias if d.get(campo) is not None]
    return sum(valores) / len(valores) if valores else None


@router.get("/{parcela_id}/clima", response_model=ClimaRespuesta)
async def actualizar_clima(parcela_id: int, dias: int = Query(30, ge=1, le=366)):
    parcela = _parcela_o_404(parcela_id)
    datos = await _consultar_power(parcela["lat"], parcela["lon"], dias)
    db.guardar_clima(parcela_id, datos)
    return _respuesta(parcela_id, datos)


@router.get("/{parcela_id}/clima/guardado", response_model=ClimaRespuesta)
def clima_guardado(parcela_id: int):
    _parcela_o_404(parcela_id)
    return _respuesta(parcela_id, db.leer_clima(parcela_id))
