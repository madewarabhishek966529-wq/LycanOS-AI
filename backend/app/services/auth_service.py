"""
Auth business logic. Endpoints (app/api/v1/endpoints/auth.py) stay thin —
parse the request, call one of these methods, return the schema. All
validation beyond basic field shape (which Pydantic already handles) and
all password/token handling lives here.
"""
import secrets
import uuid
from datetime import datetime, timedelta, timezone

from app.core.security import (
    UserRole,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.business import Business
from app.models.user import User
from app.repositories.user_repository import BusinessRepository, UserRepository
from app.schemas.auth import UserLogin, UserRegister


class AuthError(Exception):
    """Raised for any auth failure the endpoint should turn into an HTTP error."""
    def __init__(self, message: str, status_code: int = 400):
        self.message = message
        self.status_code = status_code
        super().__init__(message)


class AuthService:
    def __init__(self, user_repo: UserRepository, business_repo: BusinessRepository):
        self._users = user_repo
        self._businesses = business_repo

    async def register(self, payload: UserRegister) -> tuple[User, str, str]:
        existing = await self._users.get_by_email(payload.email)
        if existing is not None:
            raise AuthError("An account with this email already exists", status_code=409)

        # The first user of a new business is always the Owner — there is
        # no other way to create an Owner account. Manager/Cashier/
        # Employee accounts are created by an existing Owner/Manager via
        # the (Phase 7) Employee Management endpoints, not self-registration.
        business = await self._businesses.create(Business(id=uuid.uuid4(), name=payload.business_name))

        user = User(
            id=uuid.uuid4(),
            email=payload.email,
            hashed_password=hash_password(payload.password),
            full_name=payload.full_name,
            role=UserRole.OWNER,
            business_id=business.id,
        )
        user = await self._users.create(user)

        access_token = create_access_token(subject=str(user.id), role=user.role.value)
        refresh_token = create_refresh_token(subject=str(user.id))
        return user, access_token, refresh_token

    async def login(self, payload: UserLogin) -> tuple[User, str, str]:
        user = await self._users.get_by_email(payload.email)
        if user is None or not verify_password(payload.password, user.hashed_password):
            raise AuthError("Incorrect email or password", status_code=401)
        if not user.is_active:
            raise AuthError("This account has been deactivated", status_code=403)

        access_token = create_access_token(subject=str(user.id), role=user.role.value)
        refresh_token = create_refresh_token(subject=str(user.id))
        return user, access_token, refresh_token

    async def refresh(self, refresh_token: str) -> tuple[str, str]:
        payload = decode_token(refresh_token)
        if payload is None or payload.get("type") != "refresh":
            raise AuthError("Invalid or expired refresh token", status_code=401)

        user = await self._users.get_by_id(uuid.UUID(payload["sub"]))
        if user is None or not user.is_active:
            raise AuthError("Invalid or expired refresh token", status_code=401)

        new_access_token = create_access_token(subject=str(user.id), role=user.role.value)
        new_refresh_token = create_refresh_token(subject=str(user.id))
        return new_access_token, new_refresh_token

    async def get_current_user(self, access_token: str) -> User:
        payload = decode_token(access_token)
        if payload is None or payload.get("type") != "access":
            raise AuthError("Invalid or expired access token", status_code=401)

        user = await self._users.get_by_id(uuid.UUID(payload["sub"]))
        if user is None or not user.is_active:
            raise AuthError("User not found or inactive", status_code=401)
        return user

    async def request_password_reset(self, email: str) -> str | None:
        """Returns the raw reset token so the endpoint/caller can decide how
        to deliver it (email, in Settings-phase notifications). Returns
        None silently if the email doesn't exist — never reveal account
        existence through this endpoint's response."""
        user = await self._users.get_by_email(email)
        if user is None:
            return None

        token = secrets.token_urlsafe(32)
        user.reset_token = token
        user.reset_token_expires_at = datetime.now(timezone.utc) + timedelta(hours=1)
        await self._users.update(user)
        return token

    async def reset_password(self, reset_token: str, new_password: str) -> None:
        user = await self._users.get_by_reset_token(reset_token)
        if user is None or user.reset_token_expires_at is None:
            raise AuthError("Invalid or expired reset token", status_code=400)

        expires_at = user.reset_token_expires_at
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=timezone.utc)
        if expires_at < datetime.now(timezone.utc):
            raise AuthError("Invalid or expired reset token", status_code=400)

        user.hashed_password = hash_password(new_password)
        user.reset_token = None
        user.reset_token_expires_at = None
        await self._users.update(user)
