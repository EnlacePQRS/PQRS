# Dockerfile para desplegar la app de Reflex (Frontend estático con Caddy + Backend en FastAPI)
# Es ideal para plataformas de un solo puerto como Render, Railway o Hugging Face Spaces.

FROM python:3.11-slim

# Si el servicio espera un puerto diferente (por ejemplo, Render usa 10000 o dinámico), se puede configurar.
ARG PORT=8080
ARG API_URL

# Configuración de variables de entorno para Reflex y Python
ENV PORT=$PORT \
    REFLEX_API_URL=${API_URL} \
    REFLEX_REDIS_URL=redis://localhost:6379 \
    PYTHONUNBUFFERED=1

# Instalar dependencias necesarias para Node, unzip (requerido por Reflex) y redis-server
RUN apt-get update -y && apt-get install -y redis-server curl unzip && rm -rf /var/lib/apt/lists/*

# Copiar el binario de Caddy desde la imagen oficial de Caddy (para evitar agregar repositorios complejos)
COPY --from=caddy:2 /usr/bin/caddy /usr/bin/caddy

WORKDIR /app

# Copiar todo el contenido del proyecto (filtrado por .dockerignore)
COPY . .

# Instalar los requerimientos de Python
RUN pip install --no-cache-dir -r requirements.txt

# Inicializar Reflex y descargar/preparar el entorno Node.js interno de Reflex
RUN reflex init

# Compilar y exportar el frontend de forma estática, moverlo al directorio de Caddy (/srv) y limpiar el temporal
RUN reflex export --frontend-only --no-zip && mkdir -p /srv && mv .web/build/client/* /srv/ && rm -rf .web

# Parar la señal SIGKILL en vez de esperar el apagado lento si se detiene
STOPSIGNAL SIGKILL

EXPOSE $PORT

# Ejecutar migraciones si existe la carpeta alembic, encender caddy, redis y arrancar el backend en producción
CMD [ -d alembic ] && reflex db migrate; \
    caddy start && \
    redis-server --daemonize yes && \
    exec reflex run --env prod --backend-only
