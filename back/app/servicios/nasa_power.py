from datetime import date, datetime

import httpx

from app.config import POWER_TIMEOUT_S, POWER_URL

PARAMETROS = {
    "T2M": "temp_media_c",
    "T2M_MAX": "temp_max_c",
    "T2M_MIN": "temp_min_c",
    "PRECTOTCORR": "precipitacion_mm",
    "GWETTOP": "humedad_suelo",  # humedad superficial del suelo, fracción 0-1
}


FUENTE = "NASA POWER"


class ErrorPower(Exception):
    pass


async def consultar_clima(lat: float, lon: float, inicio: date, fin: date) -> list[dict]:
    params = {
        "parameters": ",".join(PARAMETROS),
        "community": "AG",
        "latitude": lat,
        "longitude": lon,
        "start": inicio.strftime("%Y%m%d"),
        "end": fin.strftime("%Y%m%d"),
        "format": "JSON",
    }
    try:
        async with httpx.AsyncClient(timeout=POWER_TIMEOUT_S) as cliente:
            resp = await cliente.get(POWER_URL, params=params)
            resp.raise_for_status()
    except httpx.HTTPError as e:
        raise ErrorPower(f"No se pudo consultar NASA POWER: {e}") from e

    return convertir_respuesta(resp.json())


def convertir_respuesta(datos: dict) -> list[dict]:
    series = datos["properties"]["parameter"]
    relleno = datos.get("header", {}).get("fill_value", -999.0)

    fechas = sorted(series["T2M"].keys())
    dias = []
    for f in fechas:
        dia = {"fecha": datetime.strptime(f, "%Y%m%d").date().isoformat()}
        for var, columna in PARAMETROS.items():
            valor = series.get(var, {}).get(f)
            dia[columna] = None if valor is None or valor == relleno else valor
        dias.append(dia)
    return dias
