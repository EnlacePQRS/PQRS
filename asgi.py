import os
import reflex as rx

# Importamos tu aplicación
from autenticacion.autenticacion import app

# Extraemos la app nativa de FastAPI (Soporta ASGI de forma directa)
application = app.backend