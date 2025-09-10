import logging
import os
import time
from contextlib import asynccontextmanager
from typing import Optional
import random

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from models import Order, OrderCreateRequest, OrderStatusUpdateRequest, OrderResponse, OrderListResponse, OrderStatus, OrderItem
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
    logger.info("Orders service started")
    yield
    # Shutdown
    logger.info("Orders service shutting down")


# Create FastAPI app
app = FastAPI(
    title="Orders Service",
    description="Manages customer orders with Dapr state store",
    version="1.0.0",
    lifespan=lifespan,
    root_path="/orders-service"
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
    return {"status": "healthy", "service": "orders"}


@app.get("/orders", response_model=OrderListResponse)
async def list_orders(
    store: DaprStateStore = Depends(get_state_store)
):
    """Get all orders."""
    start_time = time.time()
    
    try:
        # Simple query with empty filter to get all items
        query = {
            "filter": {}
        }
        
        # Execute the query
        results, _ = await store.query_items(query)
        
        # Convert results to OrderResponse objects
        items = []
        for result in results:
            try:
                order = Order.from_db_dict(result['value'])
                items.append(OrderResponse.from_order(order))
            except Exception as e:
                logger.warning(f"Failed to parse item with key {result['key']}: {str(e)}")
                continue
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Retrieved {len(items)} orders in {elapsed:.2f}ms")
        
        return OrderListResponse(items=items, total=len(items))
        
    except Exception as e:
        elapsed = (time.time() - start_time) * 1000
        logger.error(f"Failed to list orders after {elapsed:.2f}ms: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list orders: {str(e)}"
        )


@app.post("/orders", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
async def create_order(
    request: OrderCreateRequest,
    store: DaprStateStore = Depends(get_state_store)
):
    """Create a new order."""
    start_time = time.time()
    
    try:
        # Use provided order ID or generate a unique one
        if request.orderId:
            order_id = request.orderId
            # Check if ID already exists
            existing = await store.get_item(str(order_id))
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Order with ID {order_id} already exists"
                )
        else:
            # Generate a unique order ID
            order_id = random.randint(3001, 999999)
            # Check if ID already exists
            existing = await store.get_item(str(order_id))
            while existing:
                order_id = random.randint(3001, 999999)
                existing = await store.get_item(str(order_id))
        
        # Convert request items to OrderItem objects
        order_items = [
            OrderItem(productId=item.productId, quantity=item.quantity)
            for item in request.items
        ]
        
        # Create order
        order = Order(
            orderId=order_id,
            customerId=request.customerId,
            items=order_items,
            status=OrderStatus.PENDING
        )
        
        # Save to state store
        await store.save_item(str(order_id), order.to_db_dict())
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Created order {order_id} for customer {request.customerId} in {elapsed:.2f}ms")
        
        return OrderResponse.from_order(order)
        
    except Exception as e:
        logger.error(f"Error creating order: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create order: {str(e)}"
        )


@app.get("/orders/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: int,
    store: DaprStateStore = Depends(get_state_store)
):
    """Retrieve order details."""
    start_time = time.time()
    
    try:
        data = await store.get_item(str(order_id))
        
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Order {order_id} not found"
            )
        
        order = Order.from_db_dict(data)
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Retrieved order {order_id} in {elapsed:.2f}ms")
        
        return OrderResponse.from_order(order)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving order: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve order: {str(e)}"
        )


@app.put("/orders/{order_id}/status", response_model=OrderResponse)
async def update_order_status(
    order_id: int,
    request: OrderStatusUpdateRequest,
    store: DaprStateStore = Depends(get_state_store)
):
    """Update the status of an order."""
    start_time = time.time()
    
    try:
        # Get current order
        data = await store.get_item(str(order_id))
        
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Order {order_id} not found"
            )
        
        order = Order.from_db_dict(data)
        
        # Validate status transition (basic validation)
        if order.status == OrderStatus.DELIVERED and request.status != OrderStatus.DELIVERED:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot change status of a delivered order"
            )
        
        if order.status == OrderStatus.CANCELLED:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot change status of a cancelled order"
            )
        
        # Update status
        order.status = request.status
        
        # Save back to state store
        await store.save_item(str(order_id), order.to_db_dict())
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Updated order {order_id} status to {request.status} in {elapsed:.2f}ms")
        
        return OrderResponse.from_order(order)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating order status: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update order status: {str(e)}"
        )


@app.delete("/orders/{order_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_order(
    order_id: int,
    store: DaprStateStore = Depends(get_state_store)
):
    """Delete an order."""
    start_time = time.time()
    
    try:
        # Check if order exists
        data = await store.get_item(str(order_id))
        
        if not data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Order {order_id} not found"
            )
        
        # Delete from state store
        await store.delete_item(str(order_id))
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Deleted order {order_id} in {elapsed:.2f}ms")
        
        return None
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting order: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete order: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)