import logging
import os
import time
from contextlib import asynccontextmanager
from typing import Optional
import random

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from models import ReviewItem, ReviewCreateRequest, ReviewUpdateRequest, ReviewResponse, ReviewListResponse
from dapr_client import DaprStateStore

# Configure logging
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Global state store instance
state_store = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    global state_store
    state_store = DaprStateStore()
    logger.info("Reviews service started")
    yield
    # Shutdown
    logger.info("Reviews service shutting down")


# Create FastAPI app
app = FastAPI(
    title="Reviews Service",
    description="Manages customer reviews for products with Dapr state store",
    version="1.0.0",
    lifespan=lifespan,
    root_path="/reviews-service"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_state_store() -> DaprStateStore:
    """Dependency to get the state store instance."""
    if state_store is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="State store not initialized"
        )
    return state_store


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "reviews"}


@app.get("/reviews", response_model=ReviewListResponse)
async def list_reviews(
    store: DaprStateStore = Depends(get_state_store)
):
    """Get all reviews."""
    start_time = time.time()
    
    try:
        # Simple query with empty filter to get all items
        query = {
            "filter": {}
        }
        
        # Execute the query
        results, _ = await store.query_items(query)
        
        # Convert results to ReviewResponse objects
        items = []
        for result in results:
            try:
                review_item = ReviewItem.from_db_dict(result['value'])
                items.append(ReviewResponse.from_review_item(review_item))
            except Exception as e:
                logger.warning(f"Failed to parse item with key {result['key']}: {str(e)}")
                continue
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Retrieved {len(items)} reviews in {elapsed:.2f}ms")
        
        return ReviewListResponse(items=items, total=len(items))
        
    except Exception as e:
        elapsed = (time.time() - start_time) * 1000
        logger.error(f"Failed to list reviews after {elapsed:.2f}ms: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list reviews: {str(e)}"
        )


@app.post("/reviews", response_model=ReviewResponse, status_code=status.HTTP_201_CREATED)
async def create_review(
    request: ReviewCreateRequest,
    store: DaprStateStore = Depends(get_state_store)
):
    """Submit a new review."""
    start_time = time.time()
    
    try:
        # Use provided review ID or generate a unique one
        if request.reviewId:
            review_id = request.reviewId
            # Check if ID already exists
            existing = await store.get_item(str(review_id))
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Review with ID {review_id} already exists"
                )
        else:
            # Generate a unique review ID
            review_id = random.randint(4001, 999999)
            # Check if ID already exists
            existing = await store.get_item(str(review_id))
            while existing:
                review_id = random.randint(4001, 999999)
                existing = await store.get_item(str(review_id))
        
        # Create review item
        review_item = ReviewItem(
            reviewId=review_id,
            productId=request.productId,
            customerId=request.customerId,
            rating=request.rating,
            reviewText=request.reviewText if request.reviewText is not None else ""
        )
        
        # Save to state store
        await store.save_item(str(review_id), review_item.to_db_dict())
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Created review {review_id} for product {request.productId} by customer {request.customerId} in {elapsed:.2f}ms")
        
        return ReviewResponse.from_review_item(review_item)
        
    except Exception as e:
        logger.error(f"Error creating review: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create review: {str(e)}"
        )


@app.get("/reviews/{review_id}", response_model=ReviewResponse)
async def get_review(
    review_id: int,
    store: DaprStateStore = Depends(get_state_store)
):
    """Get a specific review by its ID."""
    start_time = time.time()
    
    try:
        data = await store.get_item(str(review_id))
        
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Review {review_id} not found"
            )
        
        review_item = ReviewItem.from_db_dict(data)
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Retrieved review {review_id} in {elapsed:.2f}ms")
        
        return ReviewResponse.from_review_item(review_item)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving review: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve review: {str(e)}"
        )


@app.put("/reviews/{review_id}", response_model=ReviewResponse)
async def update_review(
    review_id: int,
    request: ReviewUpdateRequest,
    store: DaprStateStore = Depends(get_state_store)
):
    """Update a review."""
    start_time = time.time()
    
    try:
        # Get current review
        data = await store.get_item(str(review_id))
        
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Review {review_id} not found"
            )
        
        review_item = ReviewItem.from_db_dict(data)
        
        # Update fields if provided
        if request.rating is not None:
            review_item.rating = request.rating
        # For reviewText, we need to check if the field was provided in the request
        # The validator converts empty strings to None, so we update if the field exists
        if hasattr(request, 'reviewText') and 'reviewText' in request.__fields_set__:
            review_item.reviewText = request.reviewText
        
        # Save back to state store
        await store.save_item(str(review_id), review_item.to_db_dict())
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Updated review {review_id} in {elapsed:.2f}ms")
        
        return ReviewResponse.from_review_item(review_item)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating review: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update review: {str(e)}"
        )


@app.delete("/reviews/{review_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_review(
    review_id: int,
    store: DaprStateStore = Depends(get_state_store)
):
    """Delete a review."""
    start_time = time.time()
    
    try:
        # Check if review exists
        data = await store.get_item(str(review_id))
        
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Review {review_id} not found"
            )
        
        # Delete from state store
        await store.delete_item(str(review_id))
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Deleted review {review_id} in {elapsed:.2f}ms")
        
        return None
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting review: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete review: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)