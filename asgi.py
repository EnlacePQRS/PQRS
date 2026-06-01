import os
import reflex as rx

# 1. Importamos tu aplicación
from autenticacion.autenticacion import app

# 2. Apuntamos al objeto FastAPI interno y protegido de la app
application = app._api