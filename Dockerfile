# Dockerfile de producción optimizado al extremo
FROM python:3.11-slim

ARG PORT=8080
ARG API_URL

# Configuración del entorno garantizando acceso a binarios locales y globales
ENV PORT=$PORT \
    REFLEX_API_URL=${API_URL} \
    REFLEX_REDIS_URL=redis://localhost:6379 \
    PYTHONUNBUFFERED=1 \
    WEB_CONCURRENCY=1 \
    TELEMETRY_ENABLED=false \
    OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    MALLOC_ARENA_MAX=2 \
    PATH="/root/.local/bin:/usr/local/bin:$PATH"

# Instalar únicamente los requerimientos mínimos de sistema
RUN apt-get update -y && apt-get install -y redis-server curl unzip && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar el código del proyecto
COPY . .

# Instalar requerimientos y asegurar la presencia global de uvicorn
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt uvicorn

# Inicializar reflex para asegurar que las rutas internas existan
RUN reflex init

STOPSIGNAL SIGKILL

EXPOSE $PORT

# Ejecución directa del binario mapeado en el PATH del contenedor
CMD redis-server --daemonize yes && \
    exec uvicorn asgi:application --host 0.0.0.0 --port $PORT --workers 1