"""
Importing every model module here ensures they're registered on
`Base.metadata` before Alembic's `env.py` (or any code calling
`Base.metadata.create_all`) runs — SQLAlchemy only knows about a model
once its module has been imported somewhere.
"""
from app.models.activity_log import ActivityLog
from app.models.attendance import Attendance
from app.models.business import Business
from app.models.category import Category
from app.models.coupon import Coupon
from app.models.customer import Customer
from app.models.employee_profile import EmployeeProfile
from app.models.invoice import Invoice, InvoiceLineItem, PaymentSplit
from app.models.product import Product
from app.models.supplier import Supplier
from app.models.user import User

__all__ = [
    "Business",
    "User",
    "Category",
    "Supplier",
    "Product",
    "Invoice",
    "InvoiceLineItem",
    "PaymentSplit",
    "Coupon",
    "Customer",
    "EmployeeProfile",
    "Attendance",
    "ActivityLog",
]
