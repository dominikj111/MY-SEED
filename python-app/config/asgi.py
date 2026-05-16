"""
ASGI entrypoint — dispatches between Django (web UI) and FastAPI (REST API).

Request path routing (nginx passes the full /py/... path):
  /py/api/v1/*  →  FastAPI
  /py/*         →  Django
"""
import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

import django

django.setup()

from django.core.asgi import get_asgi_application

_django_app = get_asgi_application()

# Import FastAPI after django.setup() so models are ready
from api.main import create_fastapi_app  # noqa: E402

_fastapi_app = create_fastapi_app()


async def application(scope, receive, send):
    """Route to FastAPI for /py/api/* and Django for everything else."""
    if scope["type"] in ("http", "websocket") and scope.get("path", "").startswith("/py/api/"):
        await _fastapi_app(scope, receive, send)
    else:
        await _django_app(scope, receive, send)
