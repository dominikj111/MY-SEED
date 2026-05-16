"""
Private API endpoints — Bearer token required.
Token is validated against the tokens_apitoken table via api.auth.get_current_user.
Mounted at /py/api/v1/ in main.py.
"""
import logging

from asgiref.sync import sync_to_async
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from api.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(tags=["private"])


class TokenRequest(BaseModel):
    email: str
    password: str
    token_name: str = "api-token"


class TokenResponse(BaseModel):
    token: str
    token_type: str = "Bearer"
    user: dict


@router.post("/auth/token", response_model=TokenResponse, status_code=201)
async def issue_token(body: TokenRequest):
    """Authenticate with email + password and receive a Bearer token."""

    @sync_to_async
    def _auth_and_create():
        from django.contrib.auth import authenticate
        from tokens.models import APIToken

        user = authenticate(username=body.email, password=body.password)
        if user is None:
            return None, None
        token = APIToken.generate(user, body.token_name)
        return user, token

    user, token = await _auth_and_create()
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    logger.info("API token issued for user %s", user.email)
    return TokenResponse(
        token=token.token,
        user={"id": user.id, "email": user.email, "username": user.username},
    )


@router.get("/me")
async def me(current_user=Depends(get_current_user)):
    """Return profile of the authenticated user."""
    return {
        "id": current_user.id,
        "email": current_user.email,
        "username": current_user.username,
        "is_staff": current_user.is_staff,
        "date_joined": current_user.date_joined.isoformat(),
    }


@router.delete("/token", status_code=204)
async def revoke_token(current_user=Depends(get_current_user)):
    """Revoke all tokens belonging to the authenticated user."""

    @sync_to_async
    def _revoke():
        from tokens.models import APIToken
        count, _ = APIToken.objects.filter(user=current_user).delete()
        return count

    count = await _revoke()
    logger.info("Revoked %d token(s) for user %s", count, current_user.email)
