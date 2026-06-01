import os
from autenticacion.autenticacion import app

# Forzar la inicialización interna del backend de Reflex
app.compile()

# Reflex guarda la app de FastAPI real dentro de un diccionario interno de sub-aplicaciones.
# Con esto la extraemos directamente sin depender de atributos variables.
application = app.backend