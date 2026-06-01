# Dockerfile de producción optimizado al extremo usando ejecución directa
FROM python:3.11-slim

ARG PORT=8080
ARG API_URL

# Configuración del entorno del sistema para restringir el uso de memoria
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

# Inicializar reflex para asegurar que las rutas internas existan
RUN reflex init

STOPSIGNAL SIGKILL

EXPOSE $PORT

# Explicación del comando de arranque definitivo:
# 1. Iniciamos Redis en segundo plano de manera ligera.
# 2. En lugar de usar 'reflex run', llamamos directamente a granian para ejecutar la app de FastAPI.
#    Buscamos el objeto 'app' dentro del archivo principal generado por Reflex (usualmente la raíz del proyecto).
#    Esto elimina por completo el intermediario de Reflex que causaba el Out Of Memory a los 30 segundos.
CMD redis-server --daemonize yes && \
    exec granian --interface asgi --host 0.0.0.0 --port $PORT --workers 1 rxconfig:app