"""Lluvia diaria de NASA GPM (producto IMERG "Late", celdas de 0.1°, unos 10 km).

Se publica con cerca de un día de retraso. Requiere EARTHDATA_TOKEN.
"""

import asyncio
from datetime import date

from app.servicios import earthdata

PRODUCTO = "GPM_3IMERGDL"
VERSION = "07"
FUENTE = "NASA GPM IMERG"

# Rejilla global regular: 3600 x 1800 celdas de 0.1°, empezando en -180° y -90°.
_CELDAS_LON = 3600
_CELDAS_LAT = 1800


def _indices(lat: float, lon: float) -> tuple[int, int]:
    i_lon = min(int((lon + 180.0) / 0.1), _CELDAS_LON - 1)
    i_lat = min(int((lat + 90.0) / 0.1), _CELDAS_LAT - 1)
    return i_lon, i_lat


async def consultar_lluvia(lat: float, lon: float, inicio: date, fin: date) -> list[dict]:
    """Lluvia en mm/día: `[{"fecha": "2026-11-13", "precipitacion_mm": 18.06}, ...]`."""
    i_lon, i_lat = _indices(lat, lon)

    async with earthdata.cliente() as http:
        granulos = await earthdata.buscar_granulos(http, PRODUCTO, VERSION, inicio, fin)
        valores = await asyncio.gather(
            *(
                # Dimensiones de la variable: (tiempo, longitud, latitud).
                earthdata.valor_celda(http, g["url"], "/precipitation", f"[0][{i_lon}]", i_lat, _CELDAS_LAT)
                for g in granulos
            )
        )

    return [
        {"fecha": g["inicio"][:10], "precipitacion_mm": valor}
        for g, valor in zip(granulos, valores)
    ]
