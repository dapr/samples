#!/bin/bash

# Script to load initial products data via the products Service API
# Usage: ./load-initial-data.sh [base_url]

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common/setup/common-utils.sh"

# Use provided base URL or default to localhost
BASE_URL="${1:-http://localhost/products-service}"

echo "Loading initial products data to: $BASE_URL"
echo "========================================"

# Wait for service to be ready
if ! wait_for_service "$BASE_URL"; then
  print_error "Service is not ready. Exiting."
  exit 1
fi

echo ""
# Initial products data with specific IDs
declare -a products=(
  '{"productId": 1001, "productName": "Smartphone XS", "productDescription": "Latest flagship smartphone with 5G connectivity and AI camera", "stockOnHand": 15, "lowStockThreshold": 5}'
  '{"productId": 1002, "productName": "Wireless Headphones Pro", "productDescription": "Noise-cancelling bluetooth headphones with 30hr battery", "stockOnHand": 8, "lowStockThreshold": 10}'
  '{"productId": 1003, "productName": "Smart Watch Ultra", "productDescription": "Fitness tracker with heart rate monitor and GPS", "stockOnHand": 12, "lowStockThreshold": 5}'
  '{"productId": 1004, "productName": "Tablet Pro 12.9\"", "productDescription": "High-performance tablet with stylus support", "stockOnHand": 2, "lowStockThreshold": 3}'
  '{"productId": 1005, "productName": "Bluetooth Speaker Max", "productDescription": "Waterproof portable speaker with 360° sound", "stockOnHand": 20, "lowStockThreshold": 8}'
  '{"productId": 1006, "productName": "Power Bank 20000mAh", "productDescription": "Fast charging power bank with multiple ports", "stockOnHand": 0, "lowStockThreshold": 5}'
  '{"productId": 1007, "productName": "Gaming Laptop RTX", "productDescription": "High-end gaming laptop with RTX 4080 graphics", "stockOnHand": 4, "lowStockThreshold": 2}'
  '{"productId": 1008, "productName": "Mechanical Keyboard RGB", "productDescription": "Gaming keyboard with customizable RGB lighting", "stockOnHand": 25, "lowStockThreshold": 10}'
  '{"productId": 1009, "productName": "4K Webcam Pro", "productDescription": "Professional webcam with AI-powered autofocus", "stockOnHand": 18, "lowStockThreshold": 7}'
  '{"productId": 1010, "productName": "USB-C Hub 10-in-1", "productDescription": "Multi-port hub with HDMI, ethernet, and card readers", "stockOnHand": 30, "lowStockThreshold": 15}'
)

# Track results
success_count=0
fail_count=0

# Create each products
for products in "${products[@]}"; do
  id=$(echo "$products" | grep -o '"productId": [0-9]*' | cut -d' ' -f2)
  name=$(echo "$products" | grep -o '"productName": "[^"]*"' | cut -d'"' -f4)
  echo -n "Creating products ID $id: $name... "
  
  response=$(make_request_with_retry "POST" "$BASE_URL/products" "$products")
  
  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | sed '$d')
  
  if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
    print_success "SUCCESS"
    ((success_count++))
  else
    print_error "FAILED (HTTP $http_code)"
    echo "  Error: $body"
    ((fail_count++))
  fi
done

echo "========================================"
echo "Summary: $success_count succeeded, $fail_count failed"

if [ $fail_count -eq 0 ]; then
  print_success "All products loaded successfully!"
  exit 0
else
  print_error "Some products failed to load"
  exit 1
fi