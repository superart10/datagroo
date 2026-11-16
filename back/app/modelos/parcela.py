from datetime import date

from pydantic import BaseModel, Field


# Los nombres de campo siguen el contrato del frontend Flutter
# (tabla `plots` de SQLite y NasaApiService): latitude / longitude / created_at.


class Coordenadas(BaseModel):
    latitude: float = Field(ge=-90, le=90, examples=[18.45])
    longitude: float = Field(ge=-180, le=180, examples=[-96.36])


class ParcelaCrear(Coordenadas):
    pass


class ParcelaRespuesta(BaseModel):
    id: int
    latitude: float
    longitude: float
    created_at: str


class ClimaDia(BaseModel):
    fecha: date
    temp_media_c: float | None
    temp_max_c: float | None
    temp_min_c: float | None
    precipitacion_mm: float | None
    humedad_suelo: float | None = None


class ResumenClima(BaseModel):
    temp_media_c: float | None
    temp_max_c: float | None
    temp_min_c: float | None
    precipitacion_total_mm: float
    dias_con_lluvia: int


class ClimaRespuesta(BaseModel):
    parcela_id: int
    fuente: str = "NASA POWER"
    inicio: date | None
    fin: date | None
    resumen: ResumenClima
    dias: list[ClimaDia]


class ClimaCoordenadasRespuesta(BaseModel):
    """Respuesta de POST /clima: las claves que lee NasaApiService en Flutter."""

    latitude: float
    longitude: float
    temperature: float | None = None  # °C, media del periodo
    precipitation: float | None = None  # mm/día, media del periodo
    soil_moisture: float | None = None  # %, humedad superficial del suelo
    precipitation_source: str | None = None  # "NASA GPM IMERG" o "NASA POWER"
    soil_moisture_source: str | None = None  # "NASA SMAP L4" o "NASA POWER"
    source: str = "NASA POWER, GPM & SMAP"
    start: date | None = None
    end: date | None = None
