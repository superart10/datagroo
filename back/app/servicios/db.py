import sqlite3
from contextlib import contextmanager

from app.config import DB_PATH


@contextmanager
def conexion():
    con = sqlite3.connect(DB_PATH)
    con.row_factory = sqlite3.Row
    con.execute("PRAGMA foreign_keys = ON")
    try:
        yield con
        con.commit()
    finally:
        con.close()


def insertar_parcela(lat: float, lon: float) -> dict:
    with conexion() as con:
        cur = con.execute("INSERT INTO parcelas (lat, lon) VALUES (?, ?)", (lat, lon))
        fila = con.execute("SELECT * FROM parcelas WHERE id = ?", (cur.lastrowid,)).fetchone()
    return dict(fila)


def obtener_parcela(parcela_id: int) -> dict | None:
    with conexion() as con:
        fila = con.execute("SELECT * FROM parcelas WHERE id = ?", (parcela_id,)).fetchone()
    return dict(fila) if fila else None


def guardar_clima(parcela_id: int, dias: list[dict]) -> None:
    with conexion() as con:
        con.executemany(
            """
            INSERT INTO clima_diario
                (parcela_id, fecha, temp_media_c, temp_max_c, temp_min_c, precipitacion_mm)
            VALUES (:parcela_id, :fecha, :temp_media_c, :temp_max_c, :temp_min_c, :precipitacion_mm)
            ON CONFLICT (parcela_id, fecha) DO UPDATE SET
                temp_media_c     = excluded.temp_media_c,
                temp_max_c       = excluded.temp_max_c,
                temp_min_c       = excluded.temp_min_c,
                precipitacion_mm = excluded.precipitacion_mm
            """,
            [{"parcela_id": parcela_id, **d} for d in dias],
        )


def leer_clima(parcela_id: int) -> list[dict]:
    with conexion() as con:
        filas = con.execute(
            """
            SELECT fecha, temp_media_c, temp_max_c, temp_min_c, precipitacion_mm
            FROM clima_diario WHERE parcela_id = ? ORDER BY fecha
            """,
            (parcela_id,),
        ).fetchall()
    return [dict(f) for f in filas]
