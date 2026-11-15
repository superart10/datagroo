from datetime import date, timedelta

from fastapi import APIRouter, HTTPException, Query, status

from app.config import POWER_RETRASO_DIAS
from app.logica.clima import resumir
from app.modelos.parcela import ClimaCoordenadasRespuesta, ClimaRespuesta, Coordenadas
from app.servicios import db, nasa_power

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
    coordenadas: Coordenadas, dias: int = Query(7, ge=1, le=366)
):
    """Recibe `{"latitude", "longitude"}` y responde con las claves que lee la
    app Flutter: `temperature` (°C), `precipitation` (mm/día) y `soil_moisture` (%).

    Un valor sin datos se omite de la respuesta (nunca va como null), porque el
    frontend solo comprueba si la clave existe antes de convertirla a número.
    """
    datos = await _consultar_power(coordenadas.latitude, coordenadas.longitude, dias)

    resumen = resumir(datos)
    lluvias = [d["precipitacion_mm"] for d in datos if d["precipitacion_mm"] is not None]
    humedades = [d["humedad_suelo"] for d in datos if d.get("humedad_suelo") is not None]

    return {
        "latitude": coordenadas.latitude,
        "longitude": coordenadas.longitude,
        "temperature": resumen["temp_media_c"],
        "precipitation": round(sum(lluvias) / len(lluvias), 2) if lluvias else None,
        # POWER entrega la humedad como fracción 0-1; el frontend la usa en %.
        "soil_moisture": round(sum(humedades) / len(humedades) * 100, 1) if humedades else None,
        "start": datos[0]["fecha"] if datos else None,
        "end": datos[-1]["fecha"] if datos else None,
    }


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
