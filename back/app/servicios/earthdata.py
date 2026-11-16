"""Acceso común a los datos de NASA Earthdata (lo usan nasa_gpm.py y smap.py).

Dos pasos, siempre por HTTPS:
1. CMR (catálogo de la NASA): lista los archivos de un producto en un rango de
   fechas.
2. OPeNDAP (requiere el token de Earthdata): pide a un archivo solo el valor de
   una celda, sin descargar el archivo completo.
"""

import asyncio
from datetime import date

import httpx

from app.config import EARTHDATA_TIMEOUT_S, EARTHDATA_TOKEN

CMR_URL = "https://cmr.earthdata.nasa.gov/search/granules.json"
OPENDAP_HOST = "https://opendap.earthdata.nasa.gov/"

# Los valores de relleno ("sin dato") de GPM y SMAP son -9999 o -9999.9.
_LIMITE_RELLENO = -9990.0

# Un archivo publicado ya no cambia, así que sus valores se pueden recordar
# mientras el servidor esté encendido. Evita repetir consultas idénticas.
_cache_valores: dict[tuple[str, str], float | None] = {}
_cache_granulos: dict[tuple[str, str, date, date], list[dict]] = {}

_limite_paralelo = asyncio.Semaphore(8)


class ErrorEarthdata(Exception):
    pass


def hay_token() -> bool:
    return bool(EARTHDATA_TOKEN)


def cliente() -> httpx.AsyncClient:
    if not EARTHDATA_TOKEN:
        raise ErrorEarthdata("Falta EARTHDATA_TOKEN en back/.env")
    return httpx.AsyncClient(
        timeout=EARTHDATA_TIMEOUT_S,
        follow_redirects=True,
        headers={"Authorization": f"Bearer {EARTHDATA_TOKEN}"},
    )


async def buscar_granulos(
    http: httpx.AsyncClient, producto: str, version: str, inicio: date, fin: date
) -> list[dict]:
    """Archivos del producto entre dos fechas: `[{"inicio": "2026-11-13T00:00:00.000Z", "url": ...}]`."""
    clave = (producto, version, inicio, fin)
    if clave in _cache_granulos:
        return _cache_granulos[clave]

    params = {
        "short_name": producto,
        "version": version,
        "temporal": f"{inicio.isoformat()}T00:00:00Z,{fin.isoformat()}T23:59:59Z",
        "sort_key": "start_date",
        "page_size": 2000,
    }
    try:
        resp = await http.get(CMR_URL, params=params)
        resp.raise_for_status()
        entradas = resp.json()["feed"]["entry"]
    except (httpx.HTTPError, KeyError, ValueError) as e:
        raise ErrorEarthdata(f"No se pudo consultar el catálogo de {producto}: {e}") from e

    granulos = []
    for entrada in entradas:
        url = next(
            (l["href"] for l in entrada.get("links", []) if l.get("href", "").startswith(OPENDAP_HOST)),
            None,
        )
        if url:
            granulos.append({"inicio": entrada["time_start"], "url": url})

    # Solo se recuerda si el rango ya está completo (no incluye días recientes
    # cuyos archivos aún pueden publicarse).
    if granulos and (date.today() - fin).days > 5:
        _cache_granulos[clave] = granulos
    return granulos


async def valor_celda(
    http: httpx.AsyncClient, url: str, variable: str, indices_previos: str, ultimo_indice: int, tamano: int
) -> float | None:
    """Valor de una celda de `variable`, o `None` si la celda no tiene dato.

    `indices_previos` son los índices de todas las dimensiones menos la última,
    por ejemplo `"[0][838]"`. Se piden dos celdas contiguas de la última
    dimensión porque la salida CSV de OPeNDAP llega vacía si se pide una sola.
    """
    if ultimo_indice + 1 < tamano:
        rango, posicion = f"[{ultimo_indice}:{ultimo_indice + 1}]", 0
    else:
        rango, posicion = f"[{ultimo_indice - 1}:{ultimo_indice}]", 1
    seleccion = f"{variable}{indices_previos}{rango}"

    clave = (url, seleccion)
    if clave in _cache_valores:
        return _cache_valores[clave]

    try:
        async with _limite_paralelo:
            resp = await http.get(f"{url}.dap.csv", params={"dap4.ce": seleccion})
        if resp.status_code in (401, 403):
            raise ErrorEarthdata(
                "Earthdata rechazó el token (caducado o sin autorización para este producto)"
            )
        resp.raise_for_status()
    except httpx.HTTPError as e:
        raise ErrorEarthdata(f"No se pudo leer {variable}: {e}") from e

    valor = _leer_csv(resp.text, variable, posicion)
    _cache_valores[clave] = valor
    return valor


def _leer_csv(texto: str, variable: str, posicion: int) -> float | None:
    """Extrae un número de una respuesta como `/precipitation[0][0], 18.055, 10.97`."""
    for linea in texto.splitlines():
        if not linea.startswith(variable):
            continue
        partes = [p.strip() for p in linea.split(",")[1:]]
        try:
            valor = float(partes[posicion])
        except (IndexError, ValueError) as e:
            raise ErrorEarthdata(f"Respuesta inesperada al leer {variable}") from e
        if valor != valor or valor <= _LIMITE_RELLENO:  # NaN o relleno
            return None
        return valor
    raise ErrorEarthdata(f"La respuesta no contiene {variable}")
