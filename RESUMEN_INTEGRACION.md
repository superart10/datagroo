# DATAGROO — Resumen de la integración frontend ↔ backend

Fecha: 15 de noviembre de 2026

Este documento resume el trabajo hecho para que la app Flutter y el backend FastAPI funcionen juntos, el estado actual y lo que queda pendiente.

## 1. Arquitectura

- **Frontend (`lib/`)**: app Flutter. Guarda terrenos, cultivos, regiones e historial en un SQLite local del dispositivo (`database_helper.dart`, tablas `regions`, `crops`, `region_cultivo`, `plots`, `plot_crop_history`).
- **Backend (`back/`)**: API FastAPI que consulta NASA POWER y devuelve datos de clima. Tiene su propia base SQLite (`back/datagroo.db`), independiente de la del teléfono.
- **Entorno Python**: `.venv/` en la raíz del proyecto, con Python 3.14.

## 2. Estado actual

- La app llama al backend con `POST /clima` y recibe datos reales de NASA POWER. Probado de punta a punta: respuesta `200 OK (Servidor NASA Backend)` con 25.31 °C, 7.52 mm/día y 60.1 % de humedad para las coordenadas 19.17, -96.13.
- `flutter analyze` no reporta errores.
- Los endpoints de `/parcelas` del backend **no funcionan todavía en uso real**, porque el backend no crea sus tablas (ver sección 6).

## 3. Contrato de la API

### `POST /clima` (el que usa la app)

Petición:
```json
{"latitude": 19.17, "longitude": -96.13}
```

Respuesta:
```json
{
  "latitude": 19.17,
  "longitude": -96.13,
  "temperature": 25.31,
  "precipitation": 7.52,
  "soil_moisture": 60.1,
  "source": "NASA POWER",
  "start": "2026-11-06",
  "end": "2026-11-12"
}
```

- `temperature`: temperatura media en °C del periodo.
- `precipitation`: lluvia media en mm/día del periodo.
- `soil_moisture`: humedad superficial del suelo en %.
- El periodo son los últimos 7 días disponibles; se cambia con `?dias=N` (1 a 366). NASA POWER publica con unos 3 días de retraso.
- Si un valor no tiene datos, la clave se omite de la respuesta (nunca va como `null`), porque la app solo comprueba si la clave existe antes de convertirla a número.
- No necesita una parcela guardada en el servidor ni usa la base de datos.

### Endpoints de parcelas (la app no los usa hoy)

| Endpoint | Petición | Respuesta |
|---|---|---|
| `POST /parcelas` | `{"latitude", "longitude"}` (campos extra se ignoran) | `{"id", "latitude", "longitude", "created_at"}` |
| `GET /parcelas/{id}` | — | `{"id", "latitude", "longitude", "created_at"}` |
| `GET /parcelas/{id}/clima?dias=30` | — | Clima día por día y resumen, en español; lo guarda en la base |
| `GET /parcelas/{id}/clima/guardado` | — | El clima ya guardado, sin consultar a la NASA |

`POST /parcelas` rechaza con 422 las coordenadas fuera de Veracruz (latitud 17.1 a 22.5, longitud -98.7 a -93.6).

## 4. Cambios realizados

### Backend

- `back/app/modelos/parcela.py`: los modelos usan `latitude`, `longitude` y `created_at` (antes `lat`, `lon`, `creada_en`), igual que la tabla `plots` del frontend. Se añadieron los modelos `Coordenadas` y `ClimaCoordenadasRespuesta`.
- `back/app/routers/clima.py`: nuevo endpoint `POST /clima` en un router aparte (`router_coordenadas`).
- `back/app/routers/parcelas.py`: traduce entre los nombres de la API (`latitude`, `longitude`, `created_at`) y las columnas de la base (`lat`, `lon`, `creada_en`).
- `back/app/servicios/nasa_power.py`: se añadió el parámetro `GWETTOP` de NASA POWER para obtener la humedad del suelo, porque `smap.py` está vacío.
- `back/app/main.py`: registra el nuevo router. El middleware CORS está activo.

### Frontend

- `lib/core/services/nasa_api_service.dart`: el endpoint ya no apunta a la NASA sino al backend. La dirección se elige así:

| Dónde corre la app | URL |
|---|---|
| Emulador de Android | `http://10.0.2.2:8000/clima` |
| Web, escritorio, simulador de iOS | `http://127.0.0.1:8000/clima` |
| Teléfono físico | la que se pase con `--dart-define=API_URL=...` |

### Entorno

- El `.venv` tenía binarios compilados para Python 3.15 (`pydantic_core`, `httptools`, `websockets` y otros) aunque el entorno es Python 3.14, y por eso FastAPI no importaba. Se reinstalaron todos los paquetes con `pip install --force-reinstall --no-cache-dir`.
- Las dependencias de Flutter se instalaron con `flutter pub get` sin errores.

## 5. Cómo ejecutar

Backend (desde la raíz del proyecto):
```powershell
cd back
..\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --port 8000
```
La documentación interactiva queda en `http://127.0.0.1:8000/docs`.

App en emulador o web:
```powershell
flutter run
```

App en teléfono físico (misma WiFi que la computadora):
```powershell
cd back
..\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```
```powershell
flutter run --dart-define=API_URL=http://<IP-de-la-PC>:8000
```

Instalar paquetes de Python siempre con el Python del entorno:
```powershell
.\.venv\Scripts\python.exe -m pip install <paquete>
```

## 6. Pendientes y detalles a tener en cuenta

1. **El backend no crea sus tablas.** No hay ningún `CREATE TABLE` para `parcelas` ni `clima_diario`, y `back/datagroo.db` no existe. Cualquier endpoint de `/parcelas` falla con error 500 (`no such table`). Solo hace falta resolverlo si se quiere que el servidor también guarde terrenos e historial de clima; `POST /clima` no lo necesita. Esquema deducido de las consultas del código:
   - `parcelas(id, lat, lon, creada_en)`
   - `clima_diario(parcela_id, fecha, temp_media_c, temp_max_c, temp_min_c, precipitacion_mm)` con clave única `(parcela_id, fecha)`
2. **Respaldo silencioso en la app.** Si el backend está apagado o tarda más de 4 segundos, la app muestra una simulación local sin avisar de error. Se distingue por el texto de estado: "Servidor NASA Backend" son datos reales; "Simulación satelital local activa" es el respaldo.
3. **Archivos vacíos en el backend**: `routers/zonas.py`, `servicios/smap.py`, `servicios/nasa_gpm.py`, `servicios/supaBase_db.py` y `logica/recomendaciones.py` no tienen código.
4. **Los terrenos solo viven en el teléfono.** La app no envía terrenos al backend; si se quiere sincronizarlos, habría que conectar el formulario de terrenos con `POST /parcelas` y ampliar la tabla del servidor con los campos de `plots` (nombre, área, cultivo, región).
