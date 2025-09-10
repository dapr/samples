from pydantic import BaseModel, Field
from typing import Optional


class CatalogueItem(BaseModel):
    productId: int = Field(..., description="Unique product identifier")
    productName: str = Field(..., description="Name of the product")
    productDescription: str = Field(..., description="Description of the product")
    avgRating: float = Field(..., ge=1.0, le=5.0, description="Average customer rating")
    reviewCount: int = Field(..., ge=0, description="Total number of reviews")

    @classmethod
    def from_db_dict(cls, data: dict) -> "CatalogueItem":
        """Create from database format with snake_case (as stored by Drasi)."""
        return cls(
            productId=data["product_id"],
            productName=data["product_name"],
            productDescription=data["product_description"],
            avgRating=data["avg_rating"],
            reviewCount=data["review_count"]
        )


class CatalogueResponse(BaseModel):
    productId: int
    productName: str
    productDescription: str
    avgRating: float
    reviewCount: int

    @staticmethod
    def from_catalogue_item(item: CatalogueItem) -> "CatalogueResponse":
        return CatalogueResponse(
            productId=item.productId,
            productName=item.productName,
            productDescription=item.productDescription,
            avgRating=round(item.avgRating, 2),
            reviewCount=item.reviewCount
        )


class CatalogueListResponse(BaseModel):
    items: list[CatalogueResponse]
    total: int