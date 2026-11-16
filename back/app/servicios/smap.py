"""Humedad superficial del suelo de NASA SMAP (producto de nivel 4, celdas de 9 km).

Se publica con unos 2 o 3 días de retraso. Requiere EARTHDATA_TOKEN.

Se usa `sm_surface_wetness`: humedad de los primeros 5 cm relativa a la
saturación, de 0 (seco) a 1 (saturado). Es la misma escala que la app muestra
como porcentaje.
"""

import asyncio
import math
from datetime import date

from app.servicios import earthdata

PRODUCTO = "SPL4SMGP"
VERSION = "008"
FUENTE = "NASA SMAP L4"

_VARIABLE = "/Geophysical_Data/sm_surface_wetness"

# Rejilla EASE-Grid 2.0 global de 9 km (proyección cilíndrica de áreas iguales).
_FILAS = 1624
_COLUMNAS = 3856
_TAMANO_CELDA_M = 9008.055210146
_X0_M = -17367530.44
_Y0_M = 7314540.83
_RADIO_M = 6378137.0
_EXCENTRICIDAD = 0.0818191908426
_PARALELO_ESTANDAR = math.radians(30.0)


def _fila_columna(lat: float, lon: float) -> tuple[int, int]:
    """Celda de la rejilla EASE-Grid 2.0 que contiene el punto."""
    e = _EXCENTRICIDAD
    k0 = math.cos(_PARALELO_ESTANDAR) / math.sqrt(1 - (e * math.sin(_PARALELO_ESTANDAR)) ** 2)
    s = math.sin(math.radians(lat))
    q = (1 - e * e) * (s / (1 - e * e * s * s) - (1 / (2 * e)) * math.log((1 - e * s) / (1 + e * s)))
    x = _RADIO_M * k0 * math.radians(lon)
    y = _RADIO_M * q / (2 * k0)
    fila = min(max(int((_Y0_M - y) / _TAMANO_CELDA_M), 0), _FILAS - 1)
    columna = min(max(int((x - _X0_M) / _TAMANO_CELDA_M), 0), _COLUMNAS - 1)
    return fila, columna


async def consultar_humedad(lat: float, lon: float, inicio: date, fin: date) -> list[dict]:
    """Humedad relativa a la saturación (0 a 1), una lectura por día.

    SMAP publica 8 archivos por día; se toma el último de cada día. Una celda
    sobre el mar o un lago no tiene dato y devuelve `None`.
    """
    fila, columna = _fila_columna(lat, lon)

    async with earthdata.cliente() as http:
        granulos = await earthdata.buscar_granulos(http, PRODUCTO, VERSION, inicio, fin)
        ultimo_del_dia: dict[str, dict] = {}
        for g in granulos:  # vienen ordenados por hora
            ultimo_del_dia[g["inicio"][:10]] = g
        elegidos = list(ultimo_del_dia.values())

        valores = await asyncio.gather(
            *(
                earthdata.valor_celda(http, g["url"], _VARIABLE, f"[{fila}]", columna, _COLUMNAS)
                for g in elegidos
            )
        )

    return [
        {"fecha": g["inicio"][:10], "humedad_suelo": valor}
        for g, valor in zip(elegidos, valores)
    ]
