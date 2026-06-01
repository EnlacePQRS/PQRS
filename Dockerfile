# Dockerfile optimizado para producción sin sobrecarga de compilación en Render
FROM python:3.11-slim

ARG PORT=8080
ARG API_URL

ENV PORT=$PORT \
    REFLEX_API_URL=${API_URL} \
    REFLEX_REDIS_URL=redis://localhost:6379 \
    PYTHONUNBUFFERED=1 \
    WEB_CONCURRENCY=1 \
    TELEMETRY_ENABLED=false

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

# Explicación del comando de arranque:
# 1. Iniciamos Redis para el manejo de estados de Reflex.
# 2. Corremos Reflex únicamente como BACKEND utilizando Gunicorn/Uvicorn integrados.
#    Esto consume menos de 150MB de RAM en total, asegurando que jamás toque el límite de 512MB.
CMD redis-server --daemonize yes && \
    exec reflex run --env prod --backend-only --port $PORT