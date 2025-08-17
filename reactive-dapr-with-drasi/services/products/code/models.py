from pydantic import BaseModel, Field
from typing import Optional, List


class ProductItem(BaseModel):
    productId: int = Field(..., description="Unique product identifier")
    productName: str = Field(..., description="Name of the product")
    productDescription: str = Field(..., description="Description of the product")
    stockOnHand: int = Field(..., ge=0, description="Current stock level")
    lowStockThreshold: int = Field(..., ge=0, description="Threshold for low stock alerts")

    def to_db_dict(self) -> dict:
        """Convert to database format with snake_case."""
        return {
            "product_id": self.productId,
            "product_name": self.productName,
            "product_description": self.productDescription,
            "stock_on_hand": self.stockOnHand,
            "low_stock_threshold": self.lowStockThreshold
        }

    @classmethod
    def from_db_dict(cls, data: dict) -> "ProductItem":
        """Create from database format with snake_case."""
        return cls(
            productId=data["product_id"],
            productName=data["product_name"],
            productDescription=data["product_description"],
            stockOnHand=data["stock_on_hand"],
            lowStockThreshold=data["low_stock_threshold"]
        )


class ProductCreateRequest(BaseModel):
    productId: int = Field(..., description="Unique product identifier")
    productName: str = Field(..., description="Name of the product")
    productDescription: str = Field(..., description="Description of the product")
    stockOnHand: int = Field(..., ge=0, description="Current stock level")
    lowStockThreshold: int = Field(..., ge=0, description="Threshold for low stock alerts")


class StockUpdateRequest(BaseModel):
    quantity: int = Field(..., gt=0, description="Quantity to increment or decrement")


class ProductResponse(BaseModel):
    productId: int
    productName: str
    productDescription: str
    stockOnHand: int
    lowStockThreshold: int
    isLowStock: bool = Field(..., description="Whether stock is below threshold")

    @staticmethod
    def from_product_item(item: ProductItem) -> "ProductResponse":
        return ProductResponse(
            productId=item.productId,
            productName=item.productName,
            productDescription=item.productDescription,
            stockOnHand=item.stockOnHand,
            lowStockThreshold=item.lowStockThreshold,
            isLowStock=item.stockOnHand <= item.lowStockThreshold
        )


class ProductListResponse(BaseModel):
    items: List[ProductResponse]
    total: int