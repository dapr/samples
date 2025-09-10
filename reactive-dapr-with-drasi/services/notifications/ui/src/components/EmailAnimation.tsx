import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Mail, Send, CheckCircle } from 'lucide-react';

interface EmailAnimationProps {
  recipients: string[];
  subject: string;
  onComplete?: () => void;
}

export const EmailAnimation: React.FC<EmailAnimationProps> = ({ recipients, subject, onComplete }) => {
  const [stage, setStage] = useState<'compose' | 'sending' | 'sent'>('compose');

  useEffect(() => {
    const timer1 = setTimeout(() => setStage('sending'), 500);
    const timer2 = setTimeout(() => setStage('sent'), 2000);
    const timer3 = setTimeout(() => {
      onComplete?.();
    }, 3000);

    return () => {
      clearTimeout(timer1);
      clearTimeout(timer2);
      clearTimeout(timer3);
    };
  }, [onComplete]);

  return (
    <div className="relative flex items-center justify-center h-32">
      <AnimatePresence mode="wait">
        {stage === 'compose' && (
          <motion.div
            key="compose"
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            exit={{ scale: 0 }}
            className="bg-white rounded-lg shadow-lg p-4 w-64"
          >
            <div className="flex items-center gap-2 mb-2">
              <Mail className="w-5 h-5 text-blue-500" />
              <span className="text-sm font-medium">New Email</span>
            </div>
            <div className="text-xs text-gray-600">
              <p className="truncate">To: {recipients[0]}</p>
              <p className="truncate">Subject: {subject}</p>
            </div>
          </motion.div>
        )}

        {stage === 'sending' && (
          <motion.div
            key="sending"
            initial={{ x: 0 }}
            animate={{ x: 300 }}
            transition={{ duration: 1, ease: "easeInOut" }}
            className="relative"
          >
            <div className="bg-blue-500 rounded-lg p-3 shadow-lg">
              <Send className="w-6 h-6 text-white" />
            </div>
            <motion.div
              className="absolute inset-0 bg-blue-400 rounded-lg"
              initial={{ scaleX: 1 }}
              animate={{ scaleX: 0 }}
              transition={{ duration: 1 }}
              style={{ originX: 0 }}
            />
          </motion.div>
        )}

        {stage === 'sent' && (
          <motion.div
            key="sent"
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            className="flex flex-col items-center gap-2"
          >
            <CheckCircle className="w-12 h-12 text-green-500" />
            <span className="text-sm text-gray-600">Email Sent!</span>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};