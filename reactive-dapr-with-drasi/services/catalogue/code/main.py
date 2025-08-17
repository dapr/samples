import logging
import os
import time
from contextlib import asynccontextmanager
from typing import Optional, List

from fastapi import FastAPI, HTTPException, Depends, status, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from models import CatalogueItem, CatalogueResponse, CatalogueListResponse
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
    logger.info("Catalogue service started")
    yield
    # Shutdown
    logger.info("Catalogue service shutting down")


# Create FastAPI app
app = FastAPI(
    title="Catalogue Service",
    description="Read-only service for product catalogue data populated by Drasi",
    version="1.0.0",
    lifespan=lifespan,
    root_path="/catalogue-service",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json"
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


@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "catalogue"}


@app.get("/api/catalogue/{product_id}", response_model=CatalogueResponse)
async def get_product_catalogue(
    product_id: int,
    store: DaprStateStore = Depends(get_state_store)
):
    """Get catalogue information for a specific product."""
    start_time = time.time()
    
    try:
        # Drasi uses the productId as the key in the state store
        data = await store.get_item(str(product_id))
        
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Product {product_id} not found in catalogue"
            )
        
        catalogue_item = CatalogueItem.from_db_dict(data)
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Retrieved catalogue data for product {product_id} in {elapsed:.2f}ms")
        
        return CatalogueResponse.from_catalogue_item(catalogue_item)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving catalogue data: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve catalogue data: {str(e)}"
        )


@app.get("/api/catalogue", response_model=CatalogueListResponse)
async def list_catalogue_items(
    store: DaprStateStore = Depends(get_state_store)
):
    """
    Get all catalogue items using Dapr state query API with an empty filter.
    """
    start_time = time.time()
    
    try:
        # Simple query with empty filter to get all items
        query = {
            "filter": {}
        }
        
        # Execute the query
        results, _ = await store.query_items(query)
        
        # Convert results to CatalogueResponse objects
        items = []
        for result in results:
            try:
                catalogue_item = CatalogueItem.from_db_dict(result['value'])
                items.append(CatalogueResponse.from_catalogue_item(catalogue_item))
            except Exception as e:
                logger.warning(f"Failed to parse item with key {result['key']}: {str(e)}")
                continue
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Retrieved {len(items)} catalogue items in {elapsed:.2f}ms")
        
        return CatalogueListResponse(
            items=items,
            total=len(items)
        )
        
    except Exception as e:
        logger.error(f"Error listing catalogue items: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list catalogue items: {str(e)}"
        )


@app.get("/api")
async def root():
    """Root endpoint with service information."""
    return {
        "service": "catalogue",
        "version": "1.0.0",
        "description": "Read-only service for product catalogue data populated by Drasi",
        "endpoints": {
            "health": "/api/health",
            "get_product": "/api/catalogue/{product_id}",
            "list_products": "/api/catalogue",
            "docs": "/api/docs",
            "redoc": "/api/redoc"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)