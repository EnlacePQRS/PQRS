# Dockerfile optimizado para producción sin sobrecarga de compilación en Render
FROM python:3.11-slim

ARG PORT=8080
ARG API_URL

# Optimizamos al máximo las variables de entorno para reducir el consumo de RAM de FastAPI/Uvicorn:
# - WEB_CONCURRENCY=1: Un solo proceso de ejecución.
# - TELEMETRY_ENABLED=false: Apaga PostHog y analíticas en segundo plano.
# - OMP_NUM_THREADS=1 y OPENBLAS_NUM_THREADS=1: Evita que librerías numéricas creen hilos fantasma.
ENV PORT=$PORT \
    REFLEX_API_URL=${API_URL} \
    REFLEX_REDIS_URL=redis://localhost:6379 \
    PYTHONUNBUFFERED=1 \
    WEB_CONCURRENCY=1 \
    TELEMETRY_ENABLED=false \
    OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    MALLOC_ARENA_MAX=2

# Instalar únicamente los requerimientos mínimos de sistema
RUN apt-get update -y && apt-get install -y redis-server curl unzip && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar el código del proyecto
COPY . .

# Instalar requerimientos de Python sin almacenar caché
RUN pip install --no-cache-dir -r requirements.txt

# Inicializar reflex de manera limpia sin descargar librerías de desarrollo de Node de forma masiva
RUN reflex init

STOPSIGNAL SIGKILL

EXPOSE $PORT

# Forzamos un entorno ultra-restringido directamente en la ejecución del comando:
CMD redis-server --daemonize yes && \
    WEB_CONCURRENCY=1 TELEMETRY_ENABLED=false exec reflex run --env prod --backend-only --backend-port $PORT