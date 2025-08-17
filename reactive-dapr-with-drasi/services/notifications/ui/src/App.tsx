import { useState, useEffect, useRef, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Bell, RefreshCw, Volume2, VolumeX } from 'lucide-react';
import { useWebSocket } from './hooks/useWebSocket';
import { EventCard } from './components/EventCard';
import { StatsCard } from './components/StatsCard';
import { ConnectionStatus } from './components/ConnectionStatus';
import { NotificationEvent, NotificationStats, WebSocketMessage } from './types';

// Determine WebSocket URL based on environment
const getWebSocketUrl = () => {
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const host = window.location.host;
  
  if (window.location.hostname === 'localhost' && window.location.port === '3000') {
    return 'ws://localhost:8000/ws';
  }
  
  // When served through ingress, use the prefix
  return `${protocol}//${host}/notifications-service/ws`;
};

function App() {
  const [events, setEvents] = useState<NotificationEvent[]>([]);
  const [stats, setStats] = useState<NotificationStats>({
    low_stock_count: 0,
    critical_stock_count: 0,
    error_count: 0,
    last_low_stock_event: null,
    last_critical_event: null,
  });
  const [soundEnabled, setSoundEnabled] = useState(true);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  const handleWebSocketMessage = useCallback((message: WebSocketMessage) => {
    switch (message.type) {
      case 'event':
        const newEvent = message.data as NotificationEvent;
        setEvents(prev => [newEvent, ...prev].slice(0, 50)); // Keep last 50 events
        
        // Play sound for critical events
        if (soundEnabled && newEvent.type === 'critical_stock' && audioRef.current) {
          audioRef.current.play().catch(e => console.error('Failed to play sound:', e));
        }
        break;
        
      case 'stats':
        setStats(message.data as NotificationStats);
        break;
        
      case 'history':
        setEvents(message.data.events.reverse()); // Reverse to show newest first
        break;
    }
  }, [soundEnabled]);

  const { isConnected, error } = useWebSocket({
    url: getWebSocketUrl(),
    onMessage: handleWebSocketMessage,
  });

  const handleReset = async () => {
    try {
      const response = await fetch('/notifications-service/reset-stats', {
        method: 'POST',
      });
      
      if (response.ok) {
        setEvents([]);
      }
    } catch (err) {
      console.error('Failed to reset stats:', err);
    }
  };

  // Create notification sound
  useEffect(() => {
    const audio = new Audio('data:audio/wav;base64,UklGRmQFAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAFAACfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8AnwCfAJ8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AOAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAKAAoACgAA==');
    audioRef.current = audio;
  }, []);

  return (
    <div className="min-h-screen bg-gray-100 p-4">
      <audio ref={audioRef} />
      
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-lg shadow-lg p-6 mb-6"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Bell className="w-8 h-8 text-blue-600" />
              <div>
                <h1 className="text-2xl font-bold text-gray-800">Notifications Dashboard</h1>
                <p className="text-sm text-gray-600">Drasi PostDaprPubSub Reaction Demo</p>
              </div>
            </div>
            
            <div className="flex items-center gap-4">
              <button
                onClick={() => setSoundEnabled(!soundEnabled)}
                className="p-2 rounded-lg hover:bg-gray-100 transition-colors"
                title={soundEnabled ? 'Disable sound' : 'Enable sound'}
              >
                {soundEnabled ? (
                  <Volume2 className="w-5 h-5 text-gray-600" />
                ) : (
                  <VolumeX className="w-5 h-5 text-gray-400" />
                )}
              </button>
              
              <button
                onClick={handleReset}
                className="flex items-center gap-2 px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
              >
                <RefreshCw className="w-4 h-4" />
                Reset Stats
              </button>
              
              <ConnectionStatus isConnected={isConnected} error={error} />
            </div>
          </div>
        </motion.div>

        {/* Statistics */}
        <StatsCard stats={stats} />

        {/* Events Feed */}
        <div className="bg-white rounded-lg shadow-lg p-6">
          <h2 className="text-xl font-semibold mb-4 text-gray-800">Recent Events</h2>
          
          {events.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              <Bell className="w-12 h-12 mx-auto mb-4 text-gray-300" />
              <p>No events yet. Waiting for stock notifications...</p>
              <p className="text-sm mt-2">Events will appear here in real-time when stock levels change.</p>
            </div>
          ) : (
            <AnimatePresence>
              <div className="space-y-4 max-h-[600px] overflow-y-auto">
                {events.map((event, index) => (
                  <EventCard key={event.id} event={event} index={index} />
                ))}
              </div>
            </AnimatePresence>
          )}
        </div>

        {/* Footer */}
        <div className="mt-6 text-center text-sm text-gray-500">
          <p>This dashboard demonstrates Drasi's PostDaprPubSub reaction capabilities.</p>
          <p>Stock events are detected by Drasi queries and published to Dapr pub/sub topics.</p>
        </div>
      </div>
    </div>
  );
}

export default App;