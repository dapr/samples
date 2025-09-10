from pydantic import BaseModel, Field, validator
from typing import Optional, List
from enum import Enum


class LoyaltyTier(str, Enum):
    BRONZE = "BRONZE"
    SILVER = "SILVER"
    GOLD = "GOLD"


class CustomerItem(BaseModel):
    customerId: int = Field(..., description="Unique customer identifier")
    customerName: str = Field(..., description="Name of the customer")
    loyaltyTier: LoyaltyTier = Field(..., description="Customer loyalty tier")
    email: str = Field(..., description="Customer email address")

    def to_db_dict(self) -> dict:
        """Convert to database format with snake_case."""
        return {
            "customer_id": self.customerId,
            "customer_name": self.customerName,
            "loyalty_tier": self.loyaltyTier.value,
            "email": self.email
        }

    @classmethod
    def from_db_dict(cls, data: dict) -> "CustomerItem":
        """Create from database format with snake_case."""
        return cls(
            customerId=data["customer_id"],
            customerName=data["customer_name"],
            loyaltyTier=LoyaltyTier(data["loyalty_tier"]),
            email=data["email"]
        )


class CustomerCreateRequest(BaseModel):
    customerId: Optional[int] = Field(None, description="Unique customer identifier (auto-generated if not provided)")
    customerName: str = Field(..., description="Name of the customer")
    email: str = Field(..., description="Customer email address")
    loyaltyTier: LoyaltyTier = Field(default=LoyaltyTier.BRONZE, description="Customer loyalty tier")

    @validator('email')
    def validate_email(cls, v):
        if '@' not in v:
            raise ValueError('Invalid email address')
        return v


class CustomerUpdateRequest(BaseModel):
    customerName: Optional[str] = Field(None, description="Name of the customer")
    loyaltyTier: Optional[LoyaltyTier] = Field(None, description="Customer loyalty tier")
    email: Optional[str] = Field(None, description="Customer email address")

    @validator('email')
    def validate_email(cls, v):
        if v and '@' not in v:
            raise ValueError('Invalid email address')
        return v


class CustomerResponse(BaseModel):
    customerId: int
    customerName: str
    loyaltyTier: LoyaltyTier
    email: str

    @staticmethod
    def from_customer_item(item: CustomerItem) -> "CustomerResponse":
        return CustomerResponse(
            customerId=item.customerId,
            customerName=item.customerName,
            loyaltyTier=item.loyaltyTier,
            email=item.email
        )


class CustomerListResponse(BaseModel):
    items: List[CustomerResponse]
    total: int