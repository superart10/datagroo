from fastapi import APIRouter, HTTPException, status

from app.config import VERACRUZ_BBOX
from app.modelos.parcela import ParcelaCrear, ParcelaRespuesta
from app.servicios import db

router = APIRouter(prefix="/parcelas", tags=["Parcelas"])


def a_respuesta(parcela: dict) -> dict:
    """Traduce la fila de la BD (lat, lon, creada_en) a los nombres del frontend."""
    return {
        "id": parcela["id"],
        "latitude": parcela["lat"],
        "longitude": parcela["lon"],
        "created_at": parcela["creada_en"],
    }


@router.post("", response_model=ParcelaRespuesta, status_code=status.HTTP_201_CREATED)
def crear_parcela(datos: ParcelaCrear):
    lat_min, lat_max, lon_min, lon_max = VERACRUZ_BBOX
    if not (lat_min <= datos.latitude <= lat_max and lon_min <= datos.longitude <= lon_max):
        raise HTTPException(
            status_code=422,
            detail="La ubicación está fuera de Veracruz",
        )
    return a_respuesta(db.insertar_parcela(datos.latitude, datos.longitude))


@router.get("/{parcela_id}", response_model=ParcelaRespuesta)
def ver_parcela(parcela_id: int):
    parcela = db.obtener_parcela(parcela_id)
    if parcela is None:
        raise HTTPException(status_code=404, detail="Parcela no encontrada")
    return a_respuesta(parcela)
