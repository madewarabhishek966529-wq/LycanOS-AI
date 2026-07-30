"""
Reusable FastAPI dependencies for authentication and RBAC. Every
protected endpoint from Phase 3 onward depends on `get_current_user` (or
`require_role(...)` when only certain roles should access it) instead of
re-deriving the user from a header manually.
"""
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import UserRole
from app.db.database import get_db
from app.models.user import User
from app.repositories.user_repository import BusinessRepository, UserRepository
from app.services.auth_service import AuthError, AuthService

bearer_scheme = HTTPBearer(auto_error=False)


def get_auth_service(db: Annotated[AsyncSession, Depends(get_db)]) -> AuthService:
    return AuthService(UserRepository(db), BusinessRepository(db))


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
    auth_service: Annotated[AuthService, Depends(get_auth_service)],
) -> User:
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    try:
        return await auth_service.get_current_user(credentials.credentials)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc


CurrentUser = Annotated[User, Depends(get_current_user)]


def require_role(*allowed_roles: UserRole):
    """Usage: `Depends(require_role(UserRole.OWNER, UserRole.MANAGER))`.
    Owner is intentionally never bypassed implicitly — pass it explicitly
    wherever it should be allowed, so access rules stay visible at the
    endpoint definition instead of hidden in a "owner can do everything"
    special case that's easy to forget when auditing permissions."""

    async def dependency(current_user: CurrentUser) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Requires one of roles: {', '.join(r.value for r in allowed_roles)}",
            )
        return current_user

    return dependency
