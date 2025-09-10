#!/bin/bash

# Script to load initial customer data via the Customer Service API
# Usage: ./load-initial-data.sh [base_url]

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common/setup/common-utils.sh"

# Use provided base URL or default to localhost
BASE_URL="${1:-http://localhost/customers-service}"

echo "Loading initial customer data to: $BASE_URL"
echo "========================================"

# Wait for service to be ready
if ! wait_for_service "$BASE_URL"; then
  print_error "Service is not ready. Exiting."
  exit 1
fi

echo ""
# Initial customer data with explicit IDs
declare -a customers=(
  '{"customerId": 1, "customerName": "Alice Johnson", "loyaltyTier": "GOLD", "email": "alice.johnson@email.com"}'
  '{"customerId": 2, "customerName": "Bob Smith", "loyaltyTier": "SILVER", "email": "bob.smith@email.com"}'
  '{"customerId": 3, "customerName": "Charlie Brown", "loyaltyTier": "BRONZE", "email": "charlie.brown@email.com"}'
  '{"customerId": 4, "customerName": "Diana Prince", "loyaltyTier": "GOLD", "email": "diana.prince@email.com"}'
  '{"customerId": 5, "customerName": "Edward Norton", "loyaltyTier": "SILVER", "email": "edward.norton@email.com"}'
  '{"customerId": 6, "customerName": "Fiona Green", "loyaltyTier": "BRONZE", "email": "fiona.green@email.com"}'
  '{"customerId": 7, "customerName": "George Wilson", "loyaltyTier": "GOLD", "email": "george.wilson@email.com"}'
  '{"customerId": 8, "customerName": "Helen Parker", "loyaltyTier": "SILVER", "email": "helen.parker@email.com"}'
  '{"customerId": 9, "customerName": "Ian McKay", "loyaltyTier": "BRONZE", "email": "ian.mckay@email.com"}'
  '{"customerId": 10, "customerName": "Julia Roberts", "loyaltyTier": "GOLD", "email": "julia.roberts@email.com"}'
)

# Track results
success_count=0
fail_count=0

# Create each customer
for customer in "${customers[@]}"; do
  id=$(echo "$customer" | grep -o '"customerId": [0-9]*' | cut -d' ' -f2)
  name=$(echo "$customer" | grep -o '"customerName": "[^"]*"' | cut -d'"' -f4)
  echo -n "Creating customer ID $id: $name... "
  
  response=$(make_request_with_retry "POST" "$BASE_URL/customers" "$customer")
  
  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | sed '$d')
  
  if [ "$http_code" = "201" ]; then
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
  print_success "All customers loaded successfully!"
  echo ""
  echo "Customer IDs: 1-10"
  exit 0
else
  print_error "Some customers failed to load"
  exit 1
fi