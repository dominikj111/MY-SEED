"""
Bearer-token authentication for FastAPI.

Tokens are stored in the `tokens_apitoken` table (Django ORM).
FastAPI is synchronous here — Django DB calls use sync_to_async so they don't
block the event loop.
"""
import logging

from asgiref.sync import sync_to_async
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

logger = logging.getLogger(__name__)

_bearer = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
):
    if not credentials:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Bearer token required")

    token_str = credentials.credentials

    @sync_to_async
    def _lookup():
        from tokens.models import APIToken

        try:
            return APIToken.objects.select_related("user").get(token=token_str)
        except APIToken.DoesNotExist:
            return None

    api_token = await _lookup()
    if api_token is None:
        logger.warning("Invalid API token presented")
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    return api_token.user
