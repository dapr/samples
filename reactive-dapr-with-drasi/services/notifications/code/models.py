from pydantic import BaseModel, Field
from typing import Dict, Any, Optional, Union, List
from datetime import datetime
from enum import Enum


class LowStockEvent(BaseModel):
    """Model for low stock event data."""
    productId: int = Field(..., description="Product identifier")
    productName: str = Field(..., description="Product name")
    stockOnHand: int = Field(..., description="Current stock level")
    lowStockThreshold: int = Field(..., description="Low stock threshold")
    timestamp: str = Field(..., description="Event timestamp")


class CriticalStockEvent(BaseModel):
    """Model for critical stock (out of stock) event data."""
    productId: int = Field(..., description="Product identifier")
    productName: str = Field(..., description="Product name")
    productDescription: str = Field(..., description="Product description")
    timestamp: str = Field(..., description="Event timestamp")


class UnpackedDrasiEvent(BaseModel):
    """Model for Drasi unpacked event format."""
    op: str = Field(..., description="Operation type: i (insert), u (update), d (delete), x (control)")
    ts_ms: int = Field(..., description="Timestamp in milliseconds")
    seq: int = Field(..., description="Sequence number")
    payload: Dict[str, Any] = Field(..., description="Event payload containing before/after states")


class NotificationStats(BaseModel):
    """Statistics about processed notifications."""
    low_stock_count: int = Field(0, description="Number of low stock events processed")
    critical_stock_count: int = Field(0, description="Number of critical stock events processed")
    error_count: int = Field(0, description="Number of processing errors")
    last_low_stock_event: Optional[str] = Field(None, description="Timestamp of last low stock event")
    last_critical_event: Optional[str] = Field(None, description="Timestamp of last critical event")


class NotificationResponse(BaseModel):
    """Response model for notification service status."""
    service: str = Field(..., description="Service name")
    status: str = Field(..., description="Service status")
    stats: NotificationStats = Field(..., description="Notification statistics")


class NotificationStatus:
    """Track notification processing status."""
    def __init__(self):
        self.low_stock_count = 0
        self.critical_stock_count = 0
        self.error_count = 0
        self.last_low_stock_event = None
        self.last_critical_event = None
    
    def get_stats(self) -> NotificationStats:
        """Get current statistics."""
        return NotificationStats(
            low_stock_count=self.low_stock_count,
            critical_stock_count=self.critical_stock_count,
            error_count=self.error_count,
            last_low_stock_event=self.last_low_stock_event,
            last_critical_event=self.last_critical_event
        )
    
    def reset(self):
        """Reset all statistics."""
        self.low_stock_count = 0
        self.critical_stock_count = 0
        self.error_count = 0
        self.last_low_stock_event = None
        self.last_critical_event = None


class EventType(str, Enum):
    """Types of notification events."""
    LOW_STOCK = "low_stock"
    CRITICAL_STOCK = "critical_stock"
    ERROR = "error"


class NotificationEvent(BaseModel):
    """Model for storing notification events in history."""
    id: str = Field(..., description="Unique event ID")
    type: EventType = Field(..., description="Type of event")
    timestamp: datetime = Field(..., description="When the event occurred")
    product_id: int = Field(..., description="Product ID")
    product_name: str = Field(..., description="Product name")
    details: Dict[str, Any] = Field(..., description="Event-specific details")
    recipients: List[str] = Field(default_factory=list, description="Email recipients")
    
    def dict(self, **kwargs):
        """Override dict to handle datetime and enum serialization."""
        d = super().dict(**kwargs)
        if isinstance(d.get('timestamp'), datetime):
            d['timestamp'] = d['timestamp'].isoformat()
        if isinstance(d.get('type'), EventType):
            d['type'] = d['type'].value
        return d


class WebSocketMessage(BaseModel):
    """Message format for WebSocket communications."""
    type: str = Field(..., description="Message type: event, stats, connected")
    data: Any = Field(..., description="Message payload")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Message timestamp")
    
    def dict(self, **kwargs):
        """Override dict to handle datetime serialization."""
        d = super().dict(**kwargs)
        if isinstance(d.get('timestamp'), datetime):
            d['timestamp'] = d['timestamp'].isoformat()
        return d


class EventHistory(BaseModel):
    """Container for event history."""
    events: List[NotificationEvent] = Field(default_factory=list, description="List of recent events")
    max_size: int = Field(100, description="Maximum number of events to store")