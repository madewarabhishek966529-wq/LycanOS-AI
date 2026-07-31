"""
Importing every model module here ensures they're registered on
`Base.metadata` before Alembic's `env.py` (or any code calling
`Base.metadata.create_all`) runs — SQLAlchemy only knows about a model
once its module has been imported somewhere.
"""
from app.models.business import Business
from app.models.category import Category
from app.models.product import Product
from app.models.supplier import Supplier
from app.models.user import User

__all__ = ["Business", "User", "Category", "Supplier", "Product"]
