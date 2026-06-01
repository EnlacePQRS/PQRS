# Dockerfile para desplegar la app de Reflex (Frontend estático con Caddy + Backend en FastAPI)
# Es ideal para plataformas de un solo puerto como Render, Railway o Hugging Face Spaces.

FROM python:3.11-slim

# Si el servicio espera un puerto diferente (por ejemplo, Render usa 10000 o dinámico), se puede configurar.
ARG PORT=8080
ARG API_URL

# Configuración de variables de entorno para Reflex y Python
# Añadimos WEB_CONCURRENCY=1 para limitar la RAM de FastAPI en tiempo de ejecución
ENV PORT=$PORT \
    REFLEX_API_URL=${API_URL} \
    REFLEX_REDIS_URL=redis://localhost:6379 \
    PYTHONUNBUFFERED=1 \
    WEB_CONCURRENCY=1 \
    GUNICORN_CMD_ARGS="--workers=1 --threads=1"

# Instalar dependencias necesarias para Node, unzip (requerido por Reflex) y redis-server
RUN apt-get update -y && apt-get install -y redis-server curl unzip && rm -rf /var/lib/apt/lists/*

# Copiar el binario de Caddy desde la imagen oficial de Caddy
COPY --from=caddy:2 /usr/bin/caddy /usr/bin/caddy

WORKDIR /app

# Copiar todo el contenido del proyecto (filtrado por .dockerignore)
COPY . .

# Copiar el Caddyfile a la ruta de configuración por defecto de Caddy
COPY Caddyfile /etc/caddy/Caddyfile

# Instalar los requerimientos de Python
RUN pip install --no-cache-dir -r requirements.txt

# ==========================================
# CONFIGURACIÓN PARA EVITAR FALTA DE MEMORIA (RAM)
# ==========================================
# Forzamos a Node.js a liberar RAM agresivamente y no pasarse de 450MB en la build
ENV NODE_OPTIONS="--max-old-space-size=450"

# Inicializar Reflex y descargar/preparar el entorno Node.js interno de Reflex
RUN reflex init

# Compilar y exportar el frontend de forma estática, moverlo al directorio de Caddy (/srv) y limpiar el temporal
RUN reflex export --frontend-only --no-zip && mkdir -p /srv && mv .web/build/client/* /srv/ && rm -rf .web

# Parar la señal SIGKILL en vez de esperar el apagado lento si se detiene
STOPSIGNAL SIGKILL

EXPOSE $PORT

# 1. Arrancamos Redis en segundo plano de manera ligera.
# 2. Corremos Caddy usando la bandera '--pingback' deshabilitada implícitamente mediante el archivo local y con una IP local no-root.
# 3. Quitamos el flag erróneo '--no-hot-reload' y dejamos que las variables de entorno controlen la RAM de Reflex de forma nativa.
CMD redis-server --daemonize yes && \
    caddy run --config /etc/caddy/Caddyfile --adapter caddyfile & \
    WEB_CONCURRENCY=1 TELEMETRY_ENABLED=false exec reflex run --env prod --backend-only