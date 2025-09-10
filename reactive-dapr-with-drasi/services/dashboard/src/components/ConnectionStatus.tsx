import { useEffect, useState } from 'react'
import { ReactionListener } from '@drasi/signalr-react'

interface ConnectionStatusProps {
  url: string
}

export default function ConnectionStatus({ url }: ConnectionStatusProps) {
  const [isConnected, setIsConnected] = useState(false)
  
  useEffect(() => {
    // Create a listener with a dummy query ID just to monitor connection
    const listener = new ReactionListener(
      url,
      'connection-monitor',
      () => {} // Empty callback since we only care about connection status
    )
    
    // Access the internal SignalR connection
    const hubConnection = (listener as any)['sigRConn'].connection
    
    // Set up connection state handlers
    hubConnection.onclose(() => setIsConnected(false))
    hubConnection.onreconnecting(() => setIsConnected(false))
    hubConnection.onreconnected(() => setIsConnected(true))
    
    // Check initial connection status
    ;(listener as any)['sigRConn'].started
      .then(() => setIsConnected(true))
      .catch(() => setIsConnected(false))
    
    // No cleanup needed as ReactionListener handles connection cleanup
  }, [url])
  
  return (
    <div className="flex items-center text-sm text-gray-500">
      <div className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-500 animate-pulse' : 'bg-red-500'} mr-2`}></div>
      {isConnected ? 'Real-time updates active' : 'Disconnected'}
    </div>
  )
}