from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import CORS_ORIGINS
from app.routers import clima, parcelas

app = FastAPI(title="DATAGROO API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(parcelas.router)
app.include_router(clima.router)
app.include_router(clima.router_coordenadas)
