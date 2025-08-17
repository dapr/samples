export interface NotificationEvent {
  id: string;
  type: 'low_stock' | 'critical_stock' | 'error';
  timestamp: string;
  product_id: number;
  product_name: string;
  details: Record<string, any>;
  recipients: string[];
}

export interface NotificationStats {
  low_stock_count: number;
  critical_stock_count: number;
  error_count: number;
  last_low_stock_event: string | null;
  last_critical_event: string | null;
}

export interface WebSocketMessage {
  type: 'event' | 'stats' | 'history' | 'connected' | 'pong';
  data: any;
  timestamp: string;
}