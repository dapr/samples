import React from 'react';
import { motion } from 'framer-motion';
import { AlertCircle, AlertTriangle, XCircle } from 'lucide-react';
import { NotificationStats } from '../types';

interface StatsCardProps {
  stats: NotificationStats;
}

export const StatsCard: React.FC<StatsCardProps> = ({ stats }) => {
  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="bg-yellow-50 border border-yellow-200 rounded-lg p-4"
      >
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm text-yellow-600 font-medium">Low Stock Events</p>
            <p className="text-3xl font-bold text-yellow-700">{stats.low_stock_count}</p>
          </div>
          <AlertCircle className="w-8 h-8 text-yellow-500" />
        </div>
        {stats.last_low_stock_event && (
          <p className="text-xs text-yellow-600 mt-2">
            Last: {new Date(stats.last_low_stock_event).toLocaleTimeString()}
          </p>
        )}
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="bg-red-50 border border-red-200 rounded-lg p-4"
      >
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm text-red-600 font-medium">Critical Stock Events</p>
            <p className="text-3xl font-bold text-red-700">{stats.critical_stock_count}</p>
          </div>
          <AlertTriangle className="w-8 h-8 text-red-500" />
        </div>
        {stats.last_critical_event && (
          <p className="text-xs text-red-600 mt-2">
            Last: {new Date(stats.last_critical_event).toLocaleTimeString()}
          </p>
        )}
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3 }}
        className="bg-gray-50 border border-gray-200 rounded-lg p-4"
      >
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm text-gray-600 font-medium">Processing Errors</p>
            <p className="text-3xl font-bold text-gray-700">{stats.error_count}</p>
          </div>
          <XCircle className="w-8 h-8 text-gray-500" />
        </div>
        <p className="text-xs text-gray-600 mt-2">
          Total Events: {stats.low_stock_count + stats.critical_stock_count}
        </p>
      </motion.div>
    </div>
  );
};