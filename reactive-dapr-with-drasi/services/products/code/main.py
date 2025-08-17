import logging
import os
import time
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from models import ProductItem, ProductCreateRequest, StockUpdateRequest, ProductResponse, ProductListResponse
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
    logger.info("Product service started")
    yield
    # Shutdown
    logger.info("Product service shutting down")


# Create FastAPI app
app = FastAPI(
    title="Product Service",
    description="Manages product stock levels with Dapr state store",
    version="1.0.0",
    lifespan=lifespan,
    root_path="/products-service"
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
    return {"status": "healthy", "service": "products"}


@app.get("/products", response_model=ProductListResponse)
async def list_products(
    store: DaprStateStore = Depends(get_state_store)
):
    """Get all products."""
    start_time = time.time()
    
    try:
        # Simple query with empty filter to get all items
        query = {
            "filter": {}
        }
        
        # Execute the query
        results, _ = await store.query_items(query)
        
        # Convert results to ProductResponse objects
        items = []
        for result in results:
            try:
                product_item = ProductItem.from_db_dict(result['value'])
                items.append(ProductResponse.from_product_item(product_item))
            except Exception as e:
                logger.warning(f"Failed to parse item with key {result['key']}: {str(e)}")
                continue
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Retrieved {len(items)} products in {elapsed:.2f}ms")
        
        return ProductListResponse(
            items=items,
            total=len(items)
        )
        
    except Exception as e:
        logger.error(f"Error listing products: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list products: {str(e)}"
        )


@app.post("/products", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
async def create_or_update_product(
    request: ProductCreateRequest,
    store: DaprStateStore = Depends(get_state_store)
):
    """Add or update a product's details."""
    start_time = time.time()
    
    try:
        # Check if item already exists
        existing = await store.get_item(str(request.productId))
        
        # Create product item
        product_item = ProductItem(
            productId=request.productId,
            productName=request.productName,
            productDescription=request.productDescription,
            stockOnHand=request.stockOnHand,
            lowStockThreshold=request.lowStockThreshold
        )
        
        # Save to state store
        await store.save_item(str(request.productId), product_item.to_db_dict())
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"{'Updated' if existing else 'Created'} product {request.productId} in {elapsed:.2f}ms")
        
        # Return appropriate status code via response
        response = ProductResponse.from_product_item(product_item)
        return JSONResponse(
            content=response.model_dump(),
            status_code=status.HTTP_200_OK if existing else status.HTTP_201_CREATED
        )
        
    except Exception as e:
        logger.error(f"Error creating/updating product: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to save product: {str(e)}"
        )


@app.get("/products/{product_id}", response_model=ProductResponse)
async def get_product(
    product_id: int,
    store: DaprStateStore = Depends(get_state_store)
):
    """Get product details."""
    start_time = time.time()
    
    try:
        data = await store.get_item(str(product_id))
        
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Product {product_id} not found"
            )
        
        product_item = ProductItem.from_db_dict(data)
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Retrieved product {product_id} in {elapsed:.2f}ms")
        
        return ProductResponse.from_product_item(product_item)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving product: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve product: {str(e)}"
        )


@app.put("/products/{product_id}/decrement", response_model=ProductResponse)
async def decrement_stock(
    product_id: int,
    request: StockUpdateRequest,
    store: DaprStateStore = Depends(get_state_store)
):
    """Decrement stock for a product."""
    start_time = time.time()
    
    try:
        # Get current inventory
        data = await store.get_item(str(product_id))
        
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Product {product_id} not found"
            )
        
        product_item = ProductItem.from_db_dict(data)
        
        # Check if we have enough stock
        if product_item.stockOnHand < request.quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Insufficient stock. Available: {product_item.stockOnHand}, Requested: {request.quantity}"
            )
        
        # Update stock
        product_item.stockOnHand -= request.quantity
        
        # Save back to state store
        await store.save_item(str(product_id), product_item.to_db_dict())
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Decremented stock for product {product_id} by {request.quantity} in {elapsed:.2f}ms")
        
        return ProductResponse.from_product_item(product_item)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error decrementing stock: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to decrement stock: {str(e)}"
        )


@app.put("/products/{product_id}/increment", response_model=ProductResponse)
async def increment_stock(
    product_id: int,
    request: StockUpdateRequest,
    store: DaprStateStore = Depends(get_state_store)
):
    """Increment stock for a product."""
    start_time = time.time()
    
    try:
        # Get current inventory
        data = await store.get_item(str(product_id))
        
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Product {product_id} not found"
            )
        
        product_item = ProductItem.from_db_dict(data)
        
        # Update stock
        product_item.stockOnHand += request.quantity
        
        # Save back to state store
        await store.save_item(str(product_id), product_item.to_db_dict())
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Incremented stock for product {product_id} by {request.quantity} in {elapsed:.2f}ms")
        
        return ProductResponse.from_product_item(product_item)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error incrementing stock: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to increment stock: {str(e)}"
        )


@app.delete("/products/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(
    product_id: int,
    store: DaprStateStore = Depends(get_state_store)
):
    """Delete a product."""
    start_time = time.time()
    
    try:
        # Check if product exists
        data = await store.get_item(str(product_id))
        
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Product {product_id} not found"
            )
        
        # Delete from state store
        await store.delete_item(str(product_id))
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Deleted product {product_id} in {elapsed:.2f}ms")
        
        return None
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting product: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete product: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)