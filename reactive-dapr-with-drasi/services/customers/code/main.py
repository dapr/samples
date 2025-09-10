import logging
import os
import time
from contextlib import asynccontextmanager
from typing import Optional
import random

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from models import CustomerItem, CustomerCreateRequest, CustomerUpdateRequest, CustomerResponse, CustomerListResponse, LoyaltyTier
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
    logger.info("Customer service started")
    yield
    # Shutdown
    logger.info("Customer service shutting down")


# Create FastAPI app
app = FastAPI(
    title="Customer Service",
    description="Manages customer information with Dapr state store",
    version="1.0.0",
    lifespan=lifespan,
    root_path="/customers-service"
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
    return {"status": "healthy", "service": "customers"}


@app.get("/customers", response_model=CustomerListResponse)
async def list_customers(
    store: DaprStateStore = Depends(get_state_store)
):
    """Get all customers."""
    start_time = time.time()
    
    try:
        # Simple query with empty filter to get all items
        query = {
            "filter": {}
        }
        
        # Execute the query
        results, _ = await store.query_items(query)
        
        # Convert results to CustomerResponse objects
        items = []
        for result in results:
            try:
                customer_item = CustomerItem.from_db_dict(result['value'])
                items.append(CustomerResponse.from_customer_item(customer_item))
            except Exception as e:
                logger.warning(f"Failed to parse item with key {result['key']}: {str(e)}")
                continue
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Retrieved {len(items)} customers in {elapsed:.2f}ms")
        
        return CustomerListResponse(items=items, total=len(items))
        
    except Exception as e:
        elapsed = (time.time() - start_time) * 1000
        logger.error(f"Failed to list customers after {elapsed:.2f}ms: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list customers: {str(e)}"
        )


@app.post("/customers", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
async def create_customer(
    request: CustomerCreateRequest,
    store: DaprStateStore = Depends(get_state_store)
):
    """Create a new customer."""
    start_time = time.time()
    
    try:
        # Use provided customer ID or generate a unique one
        if request.customerId:
            customer_id = request.customerId
            # Check if ID already exists
            existing = await store.get_item(str(customer_id))
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Customer with ID {customer_id} already exists"
                )
        else:
            # Generate a unique customer ID
            customer_id = random.randint(1000, 999999)
            # Check if ID already exists
            existing = await store.get_item(str(customer_id))
            while existing:
                customer_id = random.randint(1000, 999999)
                existing = await store.get_item(str(customer_id))
        
        # Create customer item
        customer_item = CustomerItem(
            customerId=customer_id,
            customerName=request.customerName,
            loyaltyTier=request.loyaltyTier,
            email=request.email
        )
        
        # Save to state store
        await store.save_item(str(customer_id), customer_item.to_db_dict())
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Created customer {customer_id} in {elapsed:.2f}ms")
        
        return CustomerResponse.from_customer_item(customer_item)
        
    except Exception as e:
        logger.error(f"Error creating customer: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create customer: {str(e)}"
        )


@app.get("/customers/{customer_id}", response_model=CustomerResponse)
async def get_customer(
    customer_id: int,
    store: DaprStateStore = Depends(get_state_store)
):
    """Get customer details."""
    start_time = time.time()
    
    try:
        data = await store.get_item(str(customer_id))
        
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Customer {customer_id} not found"
            )
        
        customer_item = CustomerItem.from_db_dict(data)
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Retrieved customer {customer_id} in {elapsed:.2f}ms")
        
        return CustomerResponse.from_customer_item(customer_item)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving customer: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve customer: {str(e)}"
        )


@app.put("/customers/{customer_id}", response_model=CustomerResponse)
async def update_customer(
    customer_id: int,
    request: CustomerUpdateRequest,
    store: DaprStateStore = Depends(get_state_store)
):
    """Update customer details."""
    start_time = time.time()
    
    try:
        # Get current customer
        data = await store.get_item(str(customer_id))
        
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Customer {customer_id} not found"
            )
        
        customer_item = CustomerItem.from_db_dict(data)
        
        # Update fields if provided
        if request.customerName is not None:
            customer_item.customerName = request.customerName
        if request.loyaltyTier is not None:
            customer_item.loyaltyTier = request.loyaltyTier
        if request.email is not None:
            customer_item.email = request.email
        
        # Save back to state store
        await store.save_item(str(customer_id), customer_item.to_db_dict())
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Updated customer {customer_id} in {elapsed:.2f}ms")
        
        return CustomerResponse.from_customer_item(customer_item)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating customer: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update customer: {str(e)}"
        )


@app.delete("/customers/{customer_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_customer(
    customer_id: int,
    store: DaprStateStore = Depends(get_state_store)
):
    """Delete a customer."""
    start_time = time.time()
    
    try:
        # Check if customer exists
        data = await store.get_item(str(customer_id))
        
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Customer {customer_id} not found"
            )
        
        # Delete from state store
        await store.delete_item(str(customer_id))
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Deleted customer {customer_id} in {elapsed:.2f}ms")
        
        return None
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting customer: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete customer: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)