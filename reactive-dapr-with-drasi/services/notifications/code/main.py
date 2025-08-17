import logging
import os
import json
import time
import uuid
import asyncio
from contextlib import asynccontextmanager
from datetime import datetime
from typing import Any, Dict, List, Set

from fastapi import FastAPI, HTTPException, status, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from dapr.ext.fastapi import DaprApp
from dapr.clients import DaprClient

from models import (
    LowStockEvent, 
    CriticalStockEvent, 
    UnpackedDrasiEvent,
    NotificationStatus,
    NotificationResponse,
    EventType,
    NotificationEvent,
    WebSocketMessage,
    EventHistory
)

# Configure logging
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Global notification status tracking
notification_status = NotificationStatus()

# Event history for UI
event_history = EventHistory(max_size=100)

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Set[WebSocket] = set()
        self.max_connections = 10  # Reasonable limit now that connection leak is fixed
        self._lock = asyncio.Lock()

    async def connect(self, websocket: WebSocket):
        async with self._lock:
            # Limit number of connections
            if len(self.active_connections) >= self.max_connections:
                logger.warning(f"Rejecting WebSocket connection: max connections ({self.max_connections}) reached")
                await websocket.close(code=1008, reason="Too many connections")
                return False
                
            await websocket.accept()
            self.active_connections.add(websocket)
            logger.info(f"WebSocket client connected. Total connections: {len(self.active_connections)}")
            return True

    async def disconnect(self, websocket: WebSocket):
        async with self._lock:
            self.active_connections.discard(websocket)
            logger.info(f"WebSocket client disconnected. Total connections: {len(self.active_connections)}")

    async def broadcast(self, message: dict):
        """Send message to all connected clients."""
        if self.active_connections:
            message_json = json.dumps(message)
            disconnected = set()
            
            for connection in self.active_connections:
                try:
                    await connection.send_text(message_json)
                except Exception as e:
                    logger.error(f"Error sending message to client: {e}")
                    disconnected.add(connection)
            
            # Remove disconnected clients
            self.active_connections -= disconnected

manager = ConnectionManager()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Notifications service started")
    logger.info("Subscribing to Dapr pub/sub topics:")
    logger.info("  - low-stock-events")
    logger.info("  - critical-stock-events")
    # Clear event history on startup to avoid showing duplicates from previous runs
    event_history.events.clear()
    notification_status.reset()
    logger.info("Event history cleared on startup")
    yield
    # Shutdown
    logger.info("Notifications service shutting down")


# Create FastAPI app
app = FastAPI(
    title="Notifications Service",
    description="Handles stock alerts from Drasi queries via Dapr pub/sub",
    version="1.0.0",
    lifespan=lifespan
)

# Note: Mount static files after all other routes are defined
# This will be done at the end of the file

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create Dapr app
dapr_app = DaprApp(app)


def format_timestamp(ts_ms: int) -> str:
    """Convert millisecond timestamp to readable format."""
    return datetime.fromtimestamp(ts_ms / 1000).strftime("%Y-%m-%d %H:%M:%S")


async def store_and_broadcast_event(event: NotificationEvent):
    """Store event in history and broadcast to WebSocket clients."""
    # Add to history (remove oldest if at capacity)
    if len(event_history.events) >= event_history.max_size:
        event_history.events.pop(0)
    event_history.events.append(event)
    
    # Broadcast to WebSocket clients
    message = WebSocketMessage(
        type="event",
        data=event.dict()
    )
    await manager.broadcast(message.dict())


async def broadcast_stats():
    """Broadcast updated statistics to WebSocket clients."""
    message = WebSocketMessage(
        type="stats",
        data=notification_status.get_stats().dict()
    )
    await manager.broadcast(message.dict())


def process_low_stock_event(event_data: Dict[str, Any]) -> LowStockEvent:
    """Process and validate low stock event data."""
    try:
        # Extract the Drasi event from CloudEvent wrapper
        drasi_data = event_data.get('data', event_data)
        
        # Handle unpacked Drasi event format
        unpacked_event = UnpackedDrasiEvent(**drasi_data)
        
        # Skip initial state events (ts_ms = 0 or very old events)
        if unpacked_event.ts_ms == 0:
            logger.info(f"Skipping initial state event for low stock")
            return None
            
        if unpacked_event.op == "i":  # Insert operation
            payload = unpacked_event.payload["after"]
        elif unpacked_event.op == "u":  # Update operation
            payload = unpacked_event.payload["after"]
        else:
            raise ValueError(f"Unexpected operation type: {unpacked_event.op}")
        
        return LowStockEvent(
            productId=payload["productId"],
            productName=payload["productName"],
            stockOnHand=payload["stockOnHand"],
            lowStockThreshold=payload["lowStockThreshold"],
            timestamp=format_timestamp(unpacked_event.ts_ms)
        )
    except Exception as e:
        logger.error(f"Error processing low stock event: {str(e)}")
        logger.error(f"Event data: {json.dumps(event_data, indent=2)}")
        raise


def process_critical_stock_event(event_data: Dict[str, Any]) -> CriticalStockEvent:
    """Process and validate critical stock event data."""
    try:
        # Extract the Drasi event from CloudEvent wrapper
        drasi_data = event_data.get('data', event_data)
        
        # Handle unpacked Drasi event format
        unpacked_event = UnpackedDrasiEvent(**drasi_data)
        
        # Skip initial state events (ts_ms = 0 or very old events)
        if unpacked_event.ts_ms == 0:
            logger.info(f"Skipping initial state event for critical stock")
            return None
            
        if unpacked_event.op == "i":  # Insert operation
            payload = unpacked_event.payload["after"]
        elif unpacked_event.op == "u":  # Update operation
            payload = unpacked_event.payload["after"]
        else:
            raise ValueError(f"Unexpected operation type: {unpacked_event.op}")
        
        return CriticalStockEvent(
            productId=payload["productId"],
            productName=payload["productName"],
            productDescription=payload["productDescription"],
            timestamp=format_timestamp(unpacked_event.ts_ms)
        )
    except Exception as e:
        logger.error(f"Error processing critical stock event: {str(e)}")
        logger.error(f"Event data: {json.dumps(event_data, indent=2)}")
        raise


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "notifications"}


@app.get("/status", response_model=NotificationResponse)
async def get_notification_status():
    """Get current notification processing status."""
    return NotificationResponse(
        service="notifications",
        status="active",
        stats=notification_status.get_stats()
    )


@app.post("/reset-stats")
async def reset_stats():
    """Reset notification statistics."""
    notification_status.reset()
    event_history.events.clear()
    logger.info("Notification statistics reset")
    await broadcast_stats()
    return {"message": "Statistics reset successfully"}


@app.get("/history")
async def get_event_history():
    """Get recent notification events."""
    events_list = []
    for e in event_history.events:
        try:
            events_list.append(e.dict())
        except Exception as ex:
            logger.error(f"Error serializing event in history endpoint: {ex}")
    
    return {
        "events": events_list,
        "total": len(events_list)
    }


@app.get("/test-ui")
async def test_ui():
    """Test endpoint to check UI directory."""
    ui_dir = os.path.join(os.path.dirname(__file__), "ui", "dist")
    exists = os.path.exists(ui_dir)
    files = []
    if exists:
        files = os.listdir(ui_dir)
    return {
        "ui_dir": ui_dir,
        "exists": exists,
        "files": files,
        "cwd": os.getcwd(),
        "file_location": __file__
    }


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time updates."""
    logger.info("WebSocket connection attempt received")
    
    # Try to connect (may be rejected if too many connections)
    if not await manager.connect(websocket):
        return
    
    # Send initial data
    try:
        # Send current stats
        stats_msg = WebSocketMessage(
            type="stats",
            data=notification_status.get_stats().dict()
        )
        logger.info(f"Sending initial stats: {stats_msg.dict()}")
        await websocket.send_text(json.dumps(stats_msg.dict()))
        
        # Send recent events
        try:
            events_data = []
            for e in event_history.events:
                try:
                    events_data.append(e.dict())
                except Exception as ex:
                    logger.error(f"Error serializing event {e.id}: {ex}")
            
            events_msg = WebSocketMessage(
                type="history",
                data={"events": events_data}
            )
            logger.info(f"Sending event history: {len(events_data)} events")
            msg_dict = events_msg.dict()
            msg_json = json.dumps(msg_dict)
            await websocket.send_text(msg_json)
        except Exception as e:
            logger.error(f"Error sending event history: {e}", exc_info=True)
        
        # Keep connection alive
        while True:
            # Wait for messages (ping/pong to keep alive)
            try:
                data = await websocket.receive_text()
                logger.debug(f"Received WebSocket message: {data}")
                if data == "ping":
                    # Send pong as JSON message
                    pong_msg = json.dumps({"type": "pong"})
                    await websocket.send_text(pong_msg)
            except Exception as e:
                logger.error(f"Error receiving WebSocket message: {e}")
                break
                
    except WebSocketDisconnect:
        logger.info("WebSocket disconnected normally")
    except Exception as e:
        logger.error(f"WebSocket error: {e}", exc_info=True)
    finally:
        # Always disconnect when leaving the handler
        manager.disconnect(websocket)




@dapr_app.subscribe(pubsub="notifications-pubsub", topic="low-stock-events")
async def handle_low_stock_event(event_data: dict):
    """
    Handle low stock events from Drasi.
    Simulates sending email to purchasing team.
    """
    start_time = time.time()
    
    try:
        # Process the event
        event = process_low_stock_event(event_data)
        
        # Skip if this was an initial state event
        if event is None:
            logger.info("Skipped initial state event for low stock")
            # Return SUCCESS status so Dapr ACKs the message
            return {"status": "SUCCESS"}
        
        # Log the event details
        logger.warning(f"LOW STOCK ALERT - Product: {event.productName} (ID: {event.productId})")
        logger.warning(f"  Current Stock: {event.stockOnHand}")
        logger.warning(f"  Low Stock Threshold: {event.lowStockThreshold}")
        logger.warning(f"  Timestamp: {event.timestamp}")
        
        # Simulate email notification
        print("\n" + "="*70)
        print("📧 EMAIL NOTIFICATION TO: purchasing@company.com")
        print("="*70)
        print(f"Subject: Low Stock Alert - {event.productName}")
        print(f"\nDear Purchasing Team,")
        print(f"\nThis is an automated alert to notify you that the following product")
        print(f"has reached low stock levels and requires immediate attention:")
        print(f"\nProduct Details:")
        print(f"  - Product ID: {event.productId}")
        print(f"  - Product Name: {event.productName}")
        print(f"  - Current Stock: {event.stockOnHand} units")
        print(f"  - Low Stock Threshold: {event.lowStockThreshold} units")
        print(f"  - Alert Time: {event.timestamp}")
        print(f"\nRecommended Action:")
        print(f"  - Review current orders and forecast demand")
        print(f"  - Contact suppliers for restocking options")
        print(f"  - Place purchase order if necessary")
        print(f"\nBest regards,")
        print(f"Inventory Management System")
        print("="*70 + "\n")
        
        # Store event for UI
        notification_event = NotificationEvent(
            id=str(uuid.uuid4()),
            type=EventType.LOW_STOCK,
            timestamp=datetime.utcnow(),
            product_id=event.productId,
            product_name=event.productName,
            details={
                "stockOnHand": event.stockOnHand,
                "lowStockThreshold": event.lowStockThreshold
            },
            recipients=["purchasing@company.com"]
        )
        await store_and_broadcast_event(notification_event)
        
        # Update statistics
        notification_status.low_stock_count += 1
        notification_status.last_low_stock_event = event.timestamp
        await broadcast_stats()
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Low stock event processed successfully in {elapsed:.2f}ms")
        
        # Return SUCCESS status so Dapr ACKs the message
        return {"status": "SUCCESS"}
        
    except Exception as e:
        logger.error(f"Failed to process low stock event: {str(e)}")
        notification_status.error_count += 1
        # Return DROP status to ACK the message but indicate it was not processed
        # This prevents infinite retries of malformed messages
        return {"status": "DROP"}


@dapr_app.subscribe(pubsub="notifications-pubsub", topic="critical-stock-events")
async def handle_critical_stock_event(event_data: dict):
    """
    Handle critical stock events from Drasi.
    Simulates halting sales and notifying fulfillment team.
    """
    start_time = time.time()
    
    try:
        # Process the event
        event = process_critical_stock_event(event_data)
        
        # Skip if this was an initial state event
        if event is None:
            logger.info("Skipped initial state event for critical stock")
            # Return SUCCESS status so Dapr ACKs the message
            return {"status": "SUCCESS"}
        
        # Log the critical event
        logger.critical(f"CRITICAL STOCK ALERT - Product: {event.productName} (ID: {event.productId})")
        logger.critical(f"  Product is OUT OF STOCK!")
        logger.critical(f"  Timestamp: {event.timestamp}")
        
        # Simulate critical notifications
        print("\n" + "="*70)
        print("🚨 CRITICAL ALERT - OUT OF STOCK 🚨")
        print("="*70)
        
        # Notification 1: Sales Team
        print("\n📧 EMAIL NOTIFICATION TO: sales@company.com")
        print(f"Subject: URGENT - Halt Sales for {event.productName}")
        print(f"\nDear Sales Team,")
        print(f"\nEFFECTIVE IMMEDIATELY: Please halt all sales for the following product")
        print(f"as it is now completely OUT OF STOCK:")
        print(f"\nProduct Details:")
        print(f"  - Product ID: {event.productId}")
        print(f"  - Product Name: {event.productName}")
        print(f"  - Description: {event.productDescription}")
        print(f"  - Stock Level: 0 units")
        print(f"  - Alert Time: {event.timestamp}")
        print(f"\nRequired Actions:")
        print(f"  1. Remove product from all active promotions")
        print(f"  2. Update product status to 'Out of Stock' on website")
        print(f"  3. Notify customers with pending orders")
        print(f"  4. Do not accept new orders for this product")
        
        # Notification 2: Fulfillment Team
        print("\n\n📧 EMAIL NOTIFICATION TO: fulfillment@company.com")
        print(f"Subject: URGENT - Stock Depletion Alert for {event.productName}")
        print(f"\nDear Fulfillment Team,")
        print(f"\nThis is a critical alert regarding stock depletion:")
        print(f"\nProduct Details:")
        print(f"  - Product ID: {event.productId}")
        print(f"  - Product Name: {event.productName}")
        print(f"  - Description: {event.productDescription}")
        print(f"  - Stock Level: 0 units")
        print(f"  - Alert Time: {event.timestamp}")
        print(f"\nRequired Actions:")
        print(f"  1. Review all pending orders containing this product")
        print(f"  2. Identify orders that cannot be fulfilled")
        print(f"  3. Prepare backorder notifications for affected customers")
        print(f"  4. Coordinate with purchasing for emergency restocking")
        
        # System Actions Simulation
        print("\n\n🤖 AUTOMATED SYSTEM ACTIONS:")
        print(f"  ✓ Product {event.productId} marked as 'Out of Stock' in catalog")
        print(f"  ✓ Sales channels notified to halt transactions")
        print(f"  ✓ Inventory system locked for this product")
        print(f"  ✓ Emergency restock request generated")
        print("="*70 + "\n")
        
        # Store event for UI
        notification_event = NotificationEvent(
            id=str(uuid.uuid4()),
            type=EventType.CRITICAL_STOCK,
            timestamp=datetime.utcnow(),
            product_id=event.productId,
            product_name=event.productName,
            details={
                "productDescription": event.productDescription,
                "stockLevel": 0
            },
            recipients=["sales@company.com", "fulfillment@company.com"]
        )
        await store_and_broadcast_event(notification_event)
        
        # Update statistics
        notification_status.critical_stock_count += 1
        notification_status.last_critical_event = event.timestamp
        await broadcast_stats()
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Critical stock event processed successfully in {elapsed:.2f}ms")
        
        # Return SUCCESS status so Dapr ACKs the message
        return {"status": "SUCCESS"}
        
    except Exception as e:
        logger.error(f"Failed to process critical stock event: {str(e)}")
        notification_status.error_count += 1
        # Return DROP status to ACK the message but indicate it was not processed
        # This prevents infinite retries of malformed messages
        return {"status": "DROP"}


@app.get("/api")
async def api_info():
    """API endpoint with service information."""
    return {
        "service": "notifications",
        "version": "1.0.0",
        "description": "Handles stock alerts from Drasi queries via Dapr pub/sub",
        "endpoints": {
            "health": "/health",
            "status": "/status",
            "reset_stats": "/reset-stats",
            "ui": "/"
        },
        "subscriptions": {
            "low-stock-events": "Handles products reaching low stock threshold",
            "critical-stock-events": "Handles products with zero stock"
        }
    }


# Serve static assets with proper MIME types
UI_DIR = os.path.join(os.path.dirname(__file__), "ui", "dist")
if os.path.exists(UI_DIR):
    # Mount assets directory with proper MIME type handling
    assets_dir = os.path.join(UI_DIR, "assets")
    if os.path.exists(assets_dir):
        # The ingress strips /notifications-service, so requests come as /assets/...
        app.mount("/assets", StaticFiles(directory=assets_dir), name="assets")
        logger.info(f"Serving assets from {assets_dir} at /assets")
    
    # Mount the entire UI directory for HTML and other files
    app.mount("/", StaticFiles(directory=UI_DIR, html=True), name="ui")
    logger.info(f"Serving UI from {UI_DIR}")
else:
    logger.warning(f"UI directory not found at {UI_DIR}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)