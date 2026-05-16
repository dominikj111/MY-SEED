"""
Public API endpoints — no authentication required.
Mounted at /py/api/v1/ in main.py.
"""
import logging

from fastapi import APIRouter

logger = logging.getLogger(__name__)

router = APIRouter(tags=["public"])


@router.get("/status")
async def status():
    """Service health and version info."""
    import django
    return {
        "status": "ok",
        "service": "the-seed-python",
        "stack": "Django + FastAPI",
        "django_version": django.__version__,
    }


@router.get("/ping")
async def ping():
    """Simple liveness probe."""
    return {"ping": "pong"}
