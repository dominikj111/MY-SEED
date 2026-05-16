"""
FastAPI application factory.

The app is mounted by the ASGI router in config/asgi.py.
All routes include the full /py/api/v1 prefix so nginx needs no path rewriting.
"""
import logging

from fastapi import FastAPI

from api.routers import private, public

logger = logging.getLogger(__name__)

API_PREFIX = "/py/api/v1"


def create_fastapi_app() -> FastAPI:
    app = FastAPI(
        title="the-seed Python API",
        description="FastAPI layer of the-seed Django+FastAPI seed project.",
        version="1.0.0",
        docs_url=f"{API_PREFIX}/docs",
        redoc_url=f"{API_PREFIX}/redoc",
        openapi_url=f"{API_PREFIX}/openapi.json",
    )

    app.include_router(public.router, prefix=API_PREFIX)
    app.include_router(private.router, prefix=API_PREFIX)

    @app.on_event("startup")
    async def _startup():
        logger.info("FastAPI ready — docs at %s/docs", API_PREFIX)

    return app
