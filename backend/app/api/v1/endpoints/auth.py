from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import CurrentUser, get_auth_service
from app.schemas.auth import (
    AuthResponse,
    ForgotPasswordRequest,
    RefreshTokenRequest,
    ResetPasswordRequest,
    TokenResponse,
    UserLogin,
    UserRegister,
    UserResponse,
)
from app.services.auth_service import AuthError, AuthService

router = APIRouter(prefix="/auth")


@router.post("/register", response_model=AuthResponse, status_code=201)
async def register(
    payload: UserRegister,
    auth_service: Annotated[AuthService, Depends(get_auth_service)],
) -> AuthResponse:
    try:
        user, access_token, refresh_token = await auth_service.register(payload)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc

    return AuthResponse(
        user=UserResponse.model_validate(user),
        tokens=TokenResponse(access_token=access_token, refresh_token=refresh_token),
    )


@router.post("/login", response_model=AuthResponse)
async def login(
    payload: UserLogin,
    auth_service: Annotated[AuthService, Depends(get_auth_service)],
) -> AuthResponse:
    try:
        user, access_token, refresh_token = await auth_service.login(payload)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc

    return AuthResponse(
        user=UserResponse.model_validate(user),
        tokens=TokenResponse(access_token=access_token, refresh_token=refresh_token),
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(
    payload: RefreshTokenRequest,
    auth_service: Annotated[AuthService, Depends(get_auth_service)],
) -> TokenResponse:
    try:
        access_token, refresh_token = await auth_service.refresh(payload.refresh_token)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc

    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/forgot-password", status_code=202)
async def forgot_password(
    payload: ForgotPasswordRequest,
    auth_service: Annotated[AuthService, Depends(get_auth_service)],
) -> dict:
    # Always return the same response whether or not the email exists —
    # revealing account existence here is a privacy/enumeration risk.
    # The actual token delivery (email) is wired up in the Settings phase
    # once there's an email/notification service; for now the token is
    # returned only when ENABLE_LOGGING/dev mode inspection is needed via
    # the service layer directly (e.g. in tests).
    await auth_service.request_password_reset(payload.email)
    return {"message": "If that email exists, password reset instructions have been sent."}


@router.post("/reset-password", status_code=200)
async def reset_password(
    payload: ResetPasswordRequest,
    auth_service: Annotated[AuthService, Depends(get_auth_service)],
) -> dict:
    try:
        await auth_service.reset_password(payload.reset_token, payload.new_password)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc
    return {"message": "Password has been reset successfully."}


@router.get("/me", response_model=UserResponse)
async def me(current_user: CurrentUser) -> UserResponse:
    return UserResponse.model_validate(current_user)
