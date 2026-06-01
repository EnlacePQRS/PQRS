import os

# Fix: OpenBLAS memory allocation failure on Windows (BrokenProcessPool crash).
# Must be set BEFORE numpy/pandas are imported anywhere in the process.
os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
os.environ.setdefault("MKL_NUM_THREADS", "1")
os.environ.setdefault("OMP_NUM_THREADS", "1")
os.environ.setdefault("NUMEXPR_NUM_THREADS", "1")

import reflex as rx
from pathlib import Path
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Configurar base de datos
BASE_DIR = Path(__file__).resolve().parent
DEFAULT_DATABASE_PATH = BASE_DIR / "reflex.db"
DEFAULT_DATABASE_URL = f"sqlite:///{DEFAULT_DATABASE_PATH.as_posix()}"
DATABASE_URL = os.getenv("DATABASE_URL", DEFAULT_DATABASE_URL)

# Configuración dinámica de URLs para Producción (Render + Frontend Externo)
# Si el entorno de Render no define la URL de la API, usa los puertos locales por defecto.
RENDER_BACKEND_URL = "https://pqrs-aktj.onrender.com"
API_URL = os.getenv("REFLEX_API_URL", RENDER_BACKEND_URL)

config = rx.Config(
    app_name="autenticacion",
    db_url=DATABASE_URL,
    api_url=API_URL,  # <-- CRUCIAL: Esto le dice al frontend dónde buscar el backend de Render
    cors_allowed_origins=[
        "https://frontend-aexc9eups-sistema-pqrs-projects.vercel.app",
        "http://localhost:3000"
    ],
    plugins=[
        rx.plugins.SitemapPlugin(),
        rx.plugins.TailwindV4Plugin(),
    ],
    style={
        "*": {
            "margin": "0",
            "padding": "0",
            "box_sizing": "border-box",
        },
        "html": {
            "height": "100%",
        },
        "body": {
            "margin": "0",
            "padding": "0",
            "height": "100%",
            "width": "100%",
        },
    }
)