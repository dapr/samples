#!/bin/sh

# Replace environment variables in the built app
# This allows runtime configuration of the React app

# Create a config file with environment variables
cat > /usr/share/nginx/html/env-config.js <<EOF
window.ENV = {
  VITE_SIGNALR_URL: "${VITE_SIGNALR_URL:-http://localhost:8080/hub}",
  VITE_STOCK_QUERY_ID: "${VITE_STOCK_QUERY_ID:-at-risk-orders-query}",
  VITE_GOLD_QUERY_ID: "${VITE_GOLD_QUERY_ID:-delayed-gold-orders-query}",
  VITE_API_BASE_URL: "${VITE_API_BASE_URL:-http://localhost:8001}"
};
EOF

# Update index.html to include the config script before any other scripts
sed -i 's|</head>|<script src="/dashboard/env-config.js"></script>\n</head>|' /usr/share/nginx/html/index.html

# Start nginx
nginx -g 'daemon off;'