from pydantic import BaseModel, Field, validator
from typing import List, Optional
from enum import Enum
import uuid


class OrderStatus(str, Enum):
    PENDING = "PENDING"
    PAID = "PAID"
    PROCESSING = "PROCESSING"
    SHIPPED = "SHIPPED"
    DELIVERED = "DELIVERED"
    CANCELLED = "CANCELLED"


class OrderItemRequest(BaseModel):
    productId: int = Field(..., description="Product ID")
    quantity: int = Field(..., gt=0, description="Quantity ordered")


class OrderItem(BaseModel):
    productId: int = Field(..., description="Product ID")
    quantity: int = Field(..., gt=0, description="Quantity ordered")
    
    def to_db_dict(self) -> dict:
        """Convert to database format with snake_case."""
        return {
            "product_id": self.productId,
            "quantity": self.quantity
        }
    
    @classmethod
    def from_db_dict(cls, data: dict) -> "OrderItem":
        """Create from database format with snake_case."""
        return cls(
            productId=data["product_id"],
            quantity=data["quantity"]
        )


class Order(BaseModel):
    orderId: int = Field(..., description="Unique order identifier")
    customerId: int = Field(..., description="Customer ID who placed the order")
    items: List[OrderItem] = Field(..., description="List of items in the order")
    status: OrderStatus = Field(..., description="Current order status")
    
    def to_db_dict(self) -> dict:
        """Convert to database format with snake_case."""
        return {
            "order_id": self.orderId,
            "customer_id": self.customerId,
            "items": [item.to_db_dict() for item in self.items],
            "status": self.status.value
        }
    
    @classmethod
    def from_db_dict(cls, data: dict) -> "Order":
        """Create from database format with snake_case."""
        return cls(
            orderId=data["order_id"],
            customerId=data["customer_id"],
            items=[OrderItem.from_db_dict(item) for item in data["items"]],
            status=OrderStatus(data["status"])
        )


class OrderCreateRequest(BaseModel):
    orderId: Optional[int] = Field(None, description="Unique order identifier (auto-generated if not provided)")
    customerId: int = Field(..., description="Customer ID placing the order")
    items: List[OrderItemRequest] = Field(..., min_items=1, description="List of items to order")

    @validator('items')
    def validate_unique_products(cls, v):
        product_ids = [item.productId for item in v]
        if len(product_ids) != len(set(product_ids)):
            raise ValueError('Duplicate products in order items')
        return v


class OrderStatusUpdateRequest(BaseModel):
    status: OrderStatus = Field(..., description="New order status")


class OrderResponse(BaseModel):
    orderId: int
    customerId: int
    items: List[OrderItem]
    status: OrderStatus

    @staticmethod
    def from_order(order: Order) -> "OrderResponse":
        return OrderResponse(
            orderId=order.orderId,
            customerId=order.customerId,
            items=order.items,
            status=order.status
        )


class OrderListResponse(BaseModel):
    items: List[OrderResponse]
    total: int