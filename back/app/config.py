from pathlib import Path

DB_PATH = Path(__file__).resolve().parent.parent / "datagroo.db"

POWER_URL = "https://power.larc.nasa.gov/api/temporal/daily/point"
POWER_TIMEOUT_S = 30
POWER_RETRASO_DIAS = 3

VERACRUZ_BBOX = (17.1, 22.5, -98.7, -93.6)

CORS_ORIGINS = ["*"]
