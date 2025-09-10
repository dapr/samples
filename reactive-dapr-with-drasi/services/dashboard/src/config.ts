// Configuration helper to handle both build-time and runtime environment variables
declare global {
  interface Window {
    ENV?: {
      VITE_SIGNALR_URL?: string
      VITE_STOCK_QUERY_ID?: string
      VITE_GOLD_QUERY_ID?: string
      VITE_API_BASE_URL?: string
    }
  }
}

export const getEnvVar = (key: string, defaultValue: string): string => {
  // First check runtime config (injected by docker-entrypoint.sh)
  if (typeof window !== 'undefined' && window.ENV) {
    const value = window.ENV[key as keyof typeof window.ENV]
    if (value) {
      return value
    }
  }
  
  // Fall back to build-time env vars
  const buildValue = import.meta.env[key]
  if (buildValue) {
    return buildValue
  }
  
  return defaultValue
}

export const config = {
  signalrUrl: getEnvVar('VITE_SIGNALR_URL', 'http://localhost:8080/hub'),
  stockQueryId: getEnvVar('VITE_STOCK_QUERY_ID', 'at-risk-orders-query'),
  goldQueryId: getEnvVar('VITE_GOLD_QUERY_ID', 'delayed-gold-orders-query'),
  apiBaseUrl: getEnvVar('VITE_API_BASE_URL', 'http://localhost:8001')
}