#!/bin/bash

# Script to load initial order data via the Orders Service API
# Usage: ./load-initial-data.sh [base_url]

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common/setup/common-utils.sh"

# Use provided base URL or default to localhost
BASE_URL="${1:-http://localhost/orders-service}"

echo "Loading initial order data to: $BASE_URL"
echo "========================================"

# Wait for service to be ready
if ! wait_for_service "$BASE_URL"; then
  print_error "Service is not ready. Exiting."
  exit 1
fi

echo ""
# Initial order data - PENDING orders
# Using customer IDs 1-10 and product IDs 1001-1010
# Order IDs 3001-3023 (23 orders total)
declare -a pending_orders=(
  # Customer 1 orders - tech enthusiast
  '{"orderId": 3001, "customerId": 1, "items": [{"productId": 1001, "quantity": 1}, {"productId": 1002, "quantity": 1}]}'
  '{"orderId": 3003, "customerId": 1, "items": [{"productId": 1009, "quantity": 2}]}'
  
  # Customer 2 orders - fitness focused
  '{"orderId": 3005, "customerId": 2, "items": [{"productId": 1005, "quantity": 2}, {"productId": 1006, "quantity": 1}]}'
  
  # Customer 3 orders - home office setup
  '{"orderId": 3007, "customerId": 3, "items": [{"productId": 1009, "quantity": 1}, {"productId": 1010, "quantity": 2}]}'
  
  # Customer 4 orders - mixed purchases
  '{"orderId": 3004, "customerId": 2, "items": [{"productId": 1003, "quantity": 1}]}'
  '{"orderId": 3008, "customerId": 4, "items": [{"productId": 1001, "quantity": 2}]}'
  
  # Customer 5 orders - accessories buyer
  '{"orderId": 3010, "customerId": 5, "items": [{"productId": 1006, "quantity": 3}]}'
  '{"orderId": 3011, "customerId": 5, "items": [{"productId": 1008, "quantity": 2}, {"productId": 1010, "quantity": 1}]}'
  
  # Customer 6 orders - premium buyer
  '{"orderId": 3013, "customerId": 6, "items": [{"productId": 1001, "quantity": 1}]}'
  
  # Customer 7 orders - bulk buyer
  '{"orderId": 3014, "customerId": 7, "items": [{"productId": 1005, "quantity": 5}]}'
  
  # Customer 8 orders - variety shopper
  '{"orderId": 3016, "customerId": 8, "items": [{"productId": 1002, "quantity": 1}]}'
  '{"orderId": 3017, "customerId": 8, "items": [{"productId": 1003, "quantity": 1}, {"productId": 1009, "quantity": 1}]}'
  '{"orderId": 3018, "customerId": 8, "items": [{"productId": 1008, "quantity": 1}, {"productId": 1005, "quantity": 2}]}'
  
  # Customer 9 orders - gadget lover
  '{"orderId": 3020, "customerId": 9, "items": [{"productId": 1010, "quantity": 4}]}'
  
  # Customer 10 orders - business purchases
  '{"orderId": 3022, "customerId": 10, "items": [{"productId": 1009, "quantity": 3}, {"productId": 1008, "quantity": 3}]}'
  '{"orderId": 3023, "customerId": 10, "items": [{"productId": 1002, "quantity": 5}]}'
)

# Orders with specific statuses
declare -a status_orders=(
  # PAID orders
  '{"orderId": 3002, "customerId": 1, "items": [{"productId": 1007, "quantity": 1}], "status": "PAID"}'
  '{"orderId": 3012, "customerId": 6, "items": [{"productId": 1007, "quantity": 1}, {"productId": 1004, "quantity": 1}], "status": "PAID"}'
  
  # SHIPPED orders
  '{"orderId": 3006, "customerId": 3, "items": [{"productId": 1004, "quantity": 1}, {"productId": 1008, "quantity": 1}], "status": "SHIPPED"}'
  '{"orderId": 3019, "customerId": 9, "items": [{"productId": 1001, "quantity": 1}, {"productId": 1003, "quantity": 1}, {"productId": 1009, "quantity": 1}], "status": "SHIPPED"}'
  
  # DELIVERED orders
  '{"orderId": 3009, "customerId": 4, "items": [{"productId": 1002, "quantity": 1}, {"productId": 1003, "quantity": 1}, {"productId": 1005, "quantity": 1}], "status": "DELIVERED"}'
  '{"orderId": 3021, "customerId": 10, "items": [{"productId": 1004, "quantity": 2}, {"productId": 1007, "quantity": 2}], "status": "DELIVERED"}'
  
  # CANCELLED order
  '{"orderId": 3015, "customerId": 7, "items": [{"productId": 1006, "quantity": 10}, {"productId": 1010, "quantity": 3}], "status": "CANCELLED"}'
)

# Track results
success_count=0
fail_count=0

# Create PENDING orders
echo "Creating PENDING orders..."
for order in "${pending_orders[@]}"; do
  order_id=$(echo "$order" | grep -o '"orderId": [0-9]*' | cut -d' ' -f2)
  customer_id=$(echo "$order" | grep -o '"customerId": [0-9]*' | cut -d' ' -f2)
  item_count=$(echo "$order" | grep -o '"productId"' | wc -l | tr -d ' ')
  
  echo -n "Creating order ID $order_id for Customer $customer_id with $item_count item(s)... "
  
  response=$(make_request_with_retry "POST" "$BASE_URL/orders" "$order")
  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | sed '$d')
  
  if [ "$http_code" = "201" ]; then
    print_success "SUCCESS (PENDING)"
    ((success_count++))
  else
    print_error "FAILED (HTTP $http_code)"
    echo "  Error: $body"
    ((fail_count++))
  fi
done

# Create orders with specific statuses
echo ""
echo "Creating orders with specific statuses..."
for order in "${status_orders[@]}"; do
  order_id=$(echo "$order" | grep -o '"orderId": [0-9]*' | cut -d' ' -f2)
  customer_id=$(echo "$order" | grep -o '"customerId": [0-9]*' | cut -d' ' -f2)
  item_count=$(echo "$order" | grep -o '"productId"' | wc -l | tr -d ' ')
  status=$(echo "$order" | grep -o '"status": "[^"]*"' | cut -d'"' -f4)
  
  # First create the order (API requires orders to be created as PENDING)
  order_without_status=$(echo "$order" | sed 's/, "status": "[^"]*"//')
  echo -n "Creating order ID $order_id for Customer $customer_id with $item_count item(s)... "
  
  response=$(make_request_with_retry "POST" "$BASE_URL/orders" "$order_without_status")
  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | sed '$d')
  
  if [ "$http_code" = "201" ]; then
    print_success "SUCCESS"
    ((success_count++))
    
    # Now update the status
    echo -n "  Updating order $order_id to status: $status... "
    status_json="{\"status\": \"$status\"}"
    
    status_response=$(make_request_with_retry "PUT" "$BASE_URL/orders/$order_id/status" "$status_json")
    status_http_code=$(echo "$status_response" | tail -1)
    
    if [ "$status_http_code" = "200" ]; then
      print_success "SUCCESS"
    else
      print_error "FAILED"
    fi
  else
    print_error "FAILED (HTTP $http_code)"
    echo "  Error: $body"
    ((fail_count++))
  fi
done

echo ""
echo "========================================"
echo "Summary: $success_count succeeded, $fail_count failed"
echo ""
echo "Order IDs: 3001-3023"
echo "
Total: 23 orders"

if [ $fail_count -eq 0 ]; then
  print_success "All orders loaded successfully!"
  exit 0
else
  print_error "Some orders failed to load"
  exit 1
fi