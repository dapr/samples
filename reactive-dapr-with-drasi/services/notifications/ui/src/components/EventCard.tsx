import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Package, AlertTriangle, AlertCircle, Mail, Clock } from 'lucide-react';
import { NotificationEvent } from '../types';
import { EmailAnimation } from './EmailAnimation';
import { format } from 'date-fns';

interface EventCardProps {
  event: NotificationEvent;
  index: number;
}

export const EventCard: React.FC<EventCardProps> = ({ event, index }) => {
  const [showEmail, setShowEmail] = useState(true);

  const getEventIcon = () => {
    switch (event.type) {
      case 'low_stock':
        return <AlertCircle className="w-6 h-6 text-yellow-500" />;
      case 'critical_stock':
        return <AlertTriangle className="w-6 h-6 text-red-500" />;
      default:
        return <Package className="w-6 h-6 text-gray-500" />;
    }
  };

  const getEventColor = () => {
    switch (event.type) {
      case 'low_stock':
        return 'border-yellow-200 bg-yellow-50';
      case 'critical_stock':
        return 'border-red-200 bg-red-50';
      default:
        return 'border-gray-200 bg-gray-50';
    }
  };

  const getSubject = () => {
    switch (event.type) {
      case 'low_stock':
        return `Low Stock Alert - ${event.product_name}`;
      case 'critical_stock':
        return `URGENT - Out of Stock: ${event.product_name}`;
      default:
        return 'Notification';
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, x: 100 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ delay: index * 0.1 }}
      className={`rounded-lg border-2 p-4 mb-4 ${getEventColor()} transition-all duration-300`}
    >
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-3">
          {getEventIcon()}
          <div>
            <h3 className="font-semibold text-lg">{event.product_name}</h3>
            <p className="text-sm text-gray-600">Product ID: {event.product_id}</p>
          </div>
        </div>
        <div className="flex items-center gap-2 text-sm text-gray-500">
          <Clock className="w-4 h-4" />
          {format(new Date(event.timestamp), 'HH:mm:ss')}
        </div>
      </div>

      <div className="mb-3">
        {event.type === 'low_stock' && (
          <div className="flex gap-4 text-sm">
            <span className="font-medium">Stock: {event.details.stockOnHand}</span>
            <span className="text-gray-600">Threshold: {event.details.lowStockThreshold}</span>
          </div>
        )}
        {event.type === 'critical_stock' && (
          <div className="text-sm">
            <span className="font-medium text-red-600">OUT OF STOCK</span>
            <p className="text-gray-600 mt-1">{event.details.productDescription}</p>
          </div>
        )}
      </div>

      {showEmail && (
        <div className="border-t pt-3">
          <div className="flex items-center gap-2 mb-2">
            <Mail className="w-4 h-4 text-gray-500" />
            <span className="text-sm font-medium">Sending notifications to:</span>
          </div>
          <div className="text-sm text-gray-600 mb-2">
            {event.recipients.join(', ')}
          </div>
          <EmailAnimation
            recipients={event.recipients}
            subject={getSubject()}
            onComplete={() => setShowEmail(false)}
          />
        </div>
      )}

      {!showEmail && (
        <div className="border-t pt-3 flex items-center gap-2 text-sm text-green-600">
          <Mail className="w-4 h-4" />
          <span>Email notifications sent to {event.recipients.length} recipient(s)</span>
        </div>
      )}
    </motion.div>
  );
};