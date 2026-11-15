import os
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent.parent / "datagroo.db"

POWER_URL = "https://power.larc.nasa.gov/api/temporal/daily/point"
POWER_TIMEOUT_S = 30
POWER_RETRASO_DIAS = 3

VERACRUZ_BBOX = (17.1, 22.5, -98.7, -93.6)

# Orígenes permitidos, separados por comas:
#   CORS_ORIGINS=https://datagroo.app,https://www.datagroo.app
# Sin definir, se permite cualquier origen ("*").
CORS_ORIGINS = [o.strip() for o in os.getenv("CORS_ORIGINS", "*").split(",") if o.strip()]
