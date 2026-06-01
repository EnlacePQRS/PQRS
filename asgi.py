import os
import reflex as rx

# 1. Importamos tu aplicación
from autenticacion.autenticacion import app

# 2. Extraemos el objeto FastAPI real usando la propiedad nativa de esta versión
application = app.api