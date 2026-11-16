import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

DB_PATH = BASE_DIR / "datagroo.db"

POWER_URL = "https://power.larc.nasa.gov/api/temporal/daily/point"
POWER_TIMEOUT_S = 30
POWER_RETRASO_DIAS = 3

VERACRUZ_BBOX = (17.1, 22.5, -98.7, -93.6)

# Orígenes permitidos, separados por comas:
#   CORS_ORIGINS=https://datagroo.app,https://www.datagroo.app
# Sin definir, se permite cualquier origen ("*").
CORS_ORIGINS = [o.strip() for o in os.getenv("CORS_ORIGINS", "*").split(",") if o.strip()]


def _leer_secreto(nombre: str) -> str:
    """Lee un valor de las variables de entorno o, si no está, de `back/.env`."""
    valor = os.environ.get(nombre, "")
    if valor:
        return valor.strip()
    archivo = BASE_DIR / ".env"
    if not archivo.exists():
        return ""
    for linea in archivo.read_text(encoding="utf-8-sig").splitlines():
        clave, _, contenido = linea.partition("=")
        if clave.strip() == nombre:
            return contenido.strip().strip("\"'")
    return ""


# Token de NASA Earthdata (https://urs.earthdata.nasa.gov, "Generate Token").
# Lo usan GPM (lluvia) y SMAP (humedad del suelo). Caduca cada 60 días.
# Sin token, POST /clima sigue funcionando con los datos de NASA POWER.
EARTHDATA_TOKEN = _leer_secreto("EARTHDATA_TOKEN")
EARTHDATA_TIMEOUT_S = 20
