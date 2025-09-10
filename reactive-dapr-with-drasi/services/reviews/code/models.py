from pydantic import BaseModel, Field, validator
from typing import Optional, List


class ReviewItem(BaseModel):
    reviewId: int = Field(..., description="Unique review identifier")
    productId: int = Field(..., description="Product being reviewed")
    customerId: int = Field(..., description="Customer who wrote the review")
    rating: int = Field(..., ge=1, le=5, description="Rating from 1 to 5")
    reviewText: Optional[str] = Field("", description="Optional review text")
    
    @validator('reviewText')
    def validate_review_text(cls, v):
        if v is None:
            return ""
        if len(v.strip()) == 0:
            return ""
        return v

    def to_db_dict(self) -> dict:
        """Convert to database format with snake_case."""
        return {
            "review_id": self.reviewId,
            "product_id": self.productId,
            "customer_id": self.customerId,
            "rating": self.rating,
            "review_text": self.reviewText if self.reviewText is not None else ""
        }

    @classmethod
    def from_db_dict(cls, data: dict) -> "ReviewItem":
        """Create from database format with snake_case."""
        return cls(
            reviewId=data["review_id"],
            productId=data["product_id"],
            customerId=data["customer_id"],
            rating=data["rating"],
            reviewText=data.get("review_text", "") or ""  # Handle null values
        )


class ReviewCreateRequest(BaseModel):
    reviewId: Optional[int] = Field(None, description="Unique review identifier (auto-generated if not provided)")
    productId: int = Field(..., description="Product to review")
    customerId: int = Field(..., description="Customer submitting the review")
    rating: int = Field(..., ge=1, le=5, description="Rating from 1 to 5")
    reviewText: Optional[str] = Field(None, description="Optional review text")

    @validator('reviewText')
    def validate_review_text(cls, v):
        if v is None:
            return ""
        if len(v.strip()) == 0:
            return ""
        return v


class ReviewUpdateRequest(BaseModel):
    rating: Optional[int] = Field(None, ge=1, le=5, description="Updated rating")
    reviewText: Optional[str] = Field(None, description="Updated review text")

    @validator('reviewText')
    def validate_review_text(cls, v):
        if v is None:
            return ""
        if len(v.strip()) == 0:
            return ""
        return v


class ReviewResponse(BaseModel):
    reviewId: int
    productId: int
    customerId: int
    rating: int
    reviewText: str  # Always non-null

    @staticmethod
    def from_review_item(item: ReviewItem) -> "ReviewResponse":
        return ReviewResponse(
            reviewId=item.reviewId,
            productId=item.productId,
            customerId=item.customerId,
            rating=item.rating,
            reviewText=item.reviewText if item.reviewText is not None else ""
        )


class ReviewListResponse(BaseModel):
    items: List[ReviewResponse]
    total: int