LLUVIA_MINIMA_MM = 1.0


def _promedio(valores: list[float]) -> float | None:
    return round(sum(valores) / len(valores), 2) if valores else None


def resumir(dias: list[dict]) -> dict:
    medias = [d["temp_media_c"] for d in dias if d["temp_media_c"] is not None]
    maximas = [d["temp_max_c"] for d in dias if d["temp_max_c"] is not None]
    minimas = [d["temp_min_c"] for d in dias if d["temp_min_c"] is not None]
    lluvias = [d["precipitacion_mm"] for d in dias if d["precipitacion_mm"] is not None]

    return {
        "temp_media_c": _promedio(medias),
        "temp_max_c": max(maximas) if maximas else None,
        "temp_min_c": min(minimas) if minimas else None,
        "precipitacion_total_mm": round(sum(lluvias), 2),
        "dias_con_lluvia": sum(1 for x in lluvias if x >= LLUVIA_MINIMA_MM),
    }
