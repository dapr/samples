import { useEffect, useState, useRef } from 'react';
import { ResultSet } from '@drasi/signalr-react';
import { Crown, Clock } from 'lucide-react';
import type { GoldCustomerDelay } from '../types';

interface GoldCustomerDelaysViewProps {
  signalrUrl: string;
  queryId: string;
}

// Format duration function from spec
const formatDuration = (startTimeISO: string, currentTime: number): string => {
  if (!startTimeISO) return 'N/A';
  const startTime = new Date(startTimeISO).getTime();
  if (isNaN(startTime) || startTime > currentTime) return 'N/A';

  const totalSeconds = Math.floor((currentTime - startTime) / 1000);
  if (totalSeconds < 0) return '0s'; // Should not happen if startTime <= currentTime

  const minutes = Math.floor(totalSeconds / 60);
  const remainingSeconds = totalSeconds % 60;
  if (minutes > 0) {
    return `${minutes}m ${remainingSeconds}s`;
  }
  return `${totalSeconds}s`;
};

interface GoldCustomerCardProps {
  issue: GoldCustomerDelay;
}

const GoldCustomerCard = ({ issue }: GoldCustomerCardProps) => {
  const [currentTime, setCurrentTime] = useState(window.Date.now());

  useEffect(() => {
    const timerId = setInterval(() => {
      setCurrentTime(window.Date.now());
    }, 1000);
    return () => clearInterval(timerId);
  }, []);

  const duration = formatDuration(issue.waitingSince, currentTime);

  return (
    <div className="bg-white rounded-lg shadow-md overflow-hidden border-2 border-yellow-300">
      <div className="bg-gradient-to-r from-yellow-400 to-yellow-500 px-4 py-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Crown className="w-5 h-5 text-white" />
            <span className="text-white font-semibold">Gold Customer</span>
          </div>
          <Clock className="w-5 h-5 text-white" />
        </div>
      </div>
      
      <div className="p-4">
        <div className="mb-4">
          <h3 className="text-lg font-semibold text-gray-900">{issue.customerName}</h3>
          <p className="text-sm text-gray-600">{issue.customerEmail}</p>
        </div>
        
        <div className="space-y-3">
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600">Order ID</span>
            <span className="text-sm font-medium">{issue.orderId}</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600">Customer ID</span>
            <span className="text-sm font-medium">{issue.customerId}</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600">Status</span>
            <span className="px-2 py-1 bg-orange-100 text-orange-700 rounded text-xs font-semibold">
              {issue.orderStatus}
            </span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600">Stuck Duration</span>
            <span className="text-sm font-bold text-red-600 tabular-nums">
              {duration}
            </span>
          </div>
        </div>
        
        <div className="mt-4 pt-4 border-t">
          <button className="w-full bg-indigo-50 text-indigo-700 border border-indigo-200 px-4 py-2 rounded-md text-sm font-medium hover:bg-indigo-100 transition-colors">
            Investigate Order
          </button>
        </div>
      </div>
    </div>
  );
};

export default function GoldCustomerDelaysView({ signalrUrl, queryId }: GoldCustomerDelaysViewProps) {
  const [goldIssues, setGoldIssues] = useState<GoldCustomerDelay[]>([]);
  const currentRawItemsRef = useRef<GoldCustomerDelay[]>([]);
  
  const processAndSetIssues = () => {
    const rawItems = [...currentRawItemsRef.current];
    currentRawItemsRef.current = [];
    setGoldIssues(rawItems);
  };

  if (!queryId) {
    return <div>Error: Gold Query ID is not configured.</div>;
  }

  return (
    <div>
      <div className="mb-6">
        <h2 className="text-lg font-semibold text-gray-900">Gold Customer Order Delays</h2>
        <p className="text-sm text-gray-600 mt-1">
          Gold tier customers with orders stuck in PROCESSING state.
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {goldIssues.map((issue) => (
          <GoldCustomerCard key={issue.orderId} issue={issue} />
        ))}
      </div>
       {goldIssues.length === 0 && (
            <div className="text-center py-10 text-gray-500 md:col-span-2 lg:col-span-3">
                No gold customer order delays at the moment.
            </div>
        )}

      <ResultSet url={signalrUrl} queryId={queryId}>
        {(item: GoldCustomerDelay) => {
          currentRawItemsRef.current.push(item);
          return null; 
        }}
      </ResultSet>
      <RenderWatcher onRender={processAndSetIssues} />
    </div>
  );
}

const RenderWatcher = ({ onRender }: { onRender: () => void }) => {
  useEffect(() => {
    const timeoutId = setTimeout(onRender, 0);
    return () => clearTimeout(timeoutId);
  }, [onRender]);
  return null;
};