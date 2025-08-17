import { useEffect, useRef, useState } from 'react';
import { WebSocketMessage } from '../types';

interface UseWebSocketProps {
  url: string;
  onMessage?: (message: WebSocketMessage) => void;
  reconnectInterval?: number;
}

export const useWebSocket = ({ url, onMessage, reconnectInterval = 30000 }: UseWebSocketProps) => {
  const [isConnected, setIsConnected] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const onMessageRef = useRef(onMessage);
  
  // Update the ref when onMessage changes
  useEffect(() => {
    onMessageRef.current = onMessage;
  }, [onMessage]);

  const connect = () => {
    try {
      const ws = new WebSocket(url);
      wsRef.current = ws;

      ws.onopen = () => {
        console.log('WebSocket connected');
        setIsConnected(true);
        setError(null);
        
        // Clear any reconnect timeout
        if (reconnectTimeoutRef.current) {
          clearTimeout(reconnectTimeoutRef.current);
          reconnectTimeoutRef.current = null;
        }
      };

      ws.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data) as WebSocketMessage;
          // Ignore pong messages
          if (message.type === 'pong') {
            return;
          }
          onMessageRef.current?.(message);
        } catch (err) {
          console.error('Failed to parse WebSocket message:', err);
        }
      };

      ws.onerror = (event) => {
        console.error('WebSocket error:', event);
        setError('Connection error');
      };

      ws.onclose = (event) => {
        console.log('WebSocket disconnected', event.code, event.reason);
        setIsConnected(false);
        wsRef.current = null;

        // Don't reconnect if connection was rejected due to too many connections
        if (event.code === 1008) {
          setError('Too many connections. Please close other tabs or wait before reconnecting.');
          // Use a longer delay before attempting to reconnect
          reconnectTimeoutRef.current = setTimeout(() => {
            console.log('Attempting to reconnect after connection limit...');
            connect();
          }, reconnectInterval * 2);
        } else {
          // Normal reconnect for other disconnection reasons
          reconnectTimeoutRef.current = setTimeout(() => {
            console.log('Attempting to reconnect...');
            connect();
          }, reconnectInterval);
        }
      };

      // Send periodic pings to keep connection alive
      const pingInterval = setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) {
          ws.send('ping');
        }
      }, 30000);

      // Store interval ID on the WebSocket instance for cleanup
      (ws as any).pingInterval = pingInterval;

    } catch (err) {
      console.error('Failed to connect WebSocket:', err);
      setError('Failed to connect');
      
      // Retry connection
      reconnectTimeoutRef.current = setTimeout(connect, reconnectInterval);
    }
  };

  const disconnect = () => {
    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
      reconnectTimeoutRef.current = null;
    }

    if (wsRef.current) {
      const ws = wsRef.current;
      
      // Clear ping interval
      if ((ws as any).pingInterval) {
        clearInterval((ws as any).pingInterval);
      }

      ws.close();
      wsRef.current = null;
    }
  };

  useEffect(() => {
    connect();
    return () => {
      disconnect();
    };
  }, [url]); // Only reconnect when URL changes

  return { isConnected, error };
};