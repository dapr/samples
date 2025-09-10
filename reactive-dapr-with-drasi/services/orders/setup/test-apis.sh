#!/bin/bash

# Script to perform sanity check on Orders Service APIs
# Usage: ./test-apis.sh [base_url]

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common/setup/common-utils.sh"

# Use provided base URL or default to localhost
BASE_URL="${1:-http://localhost/orders-service}"

echo "Orders Service API Sanity Check"
echo "================================="
echo "Base URL: $BASE_URL"
echo ""

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to check HTTP status code with counter
check_status() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    local body="$4"
    
    if check_http_status "$expected" "$actual" "$test_name" "$body"; then
        ((TESTS_PASSED++))
        return 0
    else
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "1. Testing Health Check"
echo "-----------------------"
response=$(make_request_with_retry "GET" "$BASE_URL/health" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "200" "$http_code" "Health check endpoint" "$body"

echo ""
echo "2. Creating Test Order"
echo "----------------------"
TEST_ORDER='{
    "customerId": 9999,
    "items": [
        {"productId": 1001, "quantity": 2},
        {"productId": 1002, "quantity": 1}
    ]
}'

response=$(make_request_with_retry "POST" "$BASE_URL/orders" "$TEST_ORDER")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "201" "$http_code" "Create order" "$body"; then
    ORDER_ID=$(echo "$body" | grep -o '"orderId":[0-9]*' | cut -d':' -f2)
    echo "  Created order with ID: $ORDER_ID"
    
    # Verify initial status is PENDING
    if echo "$body" | grep -q '"status":"PENDING"'; then
        print_test_result "Verify initial status" "true"
        ((TESTS_PASSED++))
    else
        print_test_result "Verify initial status" "false" "Initial status should be PENDING"
        ((TESTS_FAILED++))
    fi
else
    echo "Failed to create order. Stopping tests."
    exit 1
fi

echo ""
echo "3. Getting Created Order"
echo "------------------------"
response=$(make_request_with_retry "GET" "$BASE_URL/orders/$ORDER_ID" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "200" "$http_code" "Get order" "$body"; then
    # Verify the order data
    if echo "$body" | grep -q '"customerId":9999' && echo "$body" | grep -q '"productId":1001' && echo "$body" | grep -q '"quantity":2'; then
        print_test_result "Verify order data" "true"
        ((TESTS_PASSED++))
    else
        print_test_result "Verify order data" "false" "Order data doesn't match expected values"
        ((TESTS_FAILED++))
    fi
    
fi

echo ""
echo "4. Updating Order Status"
echo "------------------------"
# Test valid status transitions
STATUSES=("PAID" "PROCESSING" "SHIPPED" "DELIVERED")

for status in "${STATUSES[@]}"; do
    STATUS_UPDATE="{\"status\": \"$status\"}"
    
    echo -n "  Updating to $status... "
    response=$(make_request_with_retry "PUT" "$BASE_URL/orders/$ORDER_ID/status" "$STATUS_UPDATE")
    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        if echo "$body" | grep -q "\"status\":\"$status\""; then
            print_success "SUCCESS"
            ((TESTS_PASSED++))
        else
            print_error "FAILED - Status not updated"
            ((TESTS_FAILED++))
        fi
    else
        print_error "FAILED - HTTP $http_code"
        ((TESTS_FAILED++))
    fi
done

echo ""
echo "5. Testing Invalid Status Transition"
echo "------------------------------------"
# Try to update a delivered order (should fail)
INVALID_UPDATE='{"status": "PENDING"}'

response=$(make_request_with_retry "PUT" "$BASE_URL/orders/$ORDER_ID/status" "$INVALID_UPDATE")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "400" "$http_code" "Invalid status transition" "$body"

echo ""
echo "6. Testing Invalid Status Value"
echo "--------------------------------"
INVALID_STATUS='{"status": "INVALID_STATUS"}'

response=$(make_request_with_retry "PUT" "$BASE_URL/orders/$ORDER_ID/status" "$INVALID_STATUS")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "422" "$http_code" "Invalid status value" "$body"

echo ""
echo "7. Creating Order with Duplicate Products"
echo "-----------------------------------------"
DUPLICATE_ITEMS='{
    "customerId": 9998,
    "items": [
        {"productId": 1001, "quantity": 1},
        {"productId": 1001, "quantity": 2}
    ]
}'

response=$(make_request_with_retry "POST" "$BASE_URL/orders" "$DUPLICATE_ITEMS")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "422" "$http_code" "Duplicate products error" "$body"

echo ""
echo "8. Creating Order with Empty Items"
echo "-----------------------------------"
EMPTY_ITEMS='{"customerId": 9997, "items": []}'

response=$(make_request_with_retry "POST" "$BASE_URL/orders" "$EMPTY_ITEMS")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "422" "$http_code" "Empty items error" "$body"

echo ""
echo "9. Creating Order with Invalid Quantity"
echo "----------------------------------------"
INVALID_QUANTITY='{
    "customerId": 9996,
    "items": [{"productId": 1001, "quantity": 0}]
}'

response=$(make_request_with_retry "POST" "$BASE_URL/orders" "$INVALID_QUANTITY")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "422" "$http_code" "Invalid quantity error" "$body"

echo ""
echo "10. Testing 404 for Non-existent Order"
echo "---------------------------------------"
response=$(make_request_with_retry "GET" "$BASE_URL/orders/999999999" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "404" "$http_code" "Get non-existent order" "$body"

echo ""
echo "11. Creating Cancelled Order"
echo "----------------------------"
CANCEL_ORDER='{
    "customerId": 9995,
    "items": [{"productId": 1005, "quantity": 1}]
}'

response=$(make_request_with_retry "POST" "$BASE_URL/orders" "$CANCEL_ORDER")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "201" ]; then
    CANCEL_ORDER_ID=$(echo "$body" | grep -o '"orderId":[0-9]*' | cut -d':' -f2)
    echo "  Created order to cancel with ID: $CANCEL_ORDER_ID"
    ((TESTS_PASSED++))
    
    # Cancel the order
    CANCEL_UPDATE='{"status": "CANCELLED"}'
    response=$(make_request_with_retry "PUT" "$BASE_URL/orders/$CANCEL_ORDER_ID/status" "$CANCEL_UPDATE")
    http_code=$(echo "$response" | tail -1)
    
    if check_status "200" "$http_code" "Cancel order" "$body"; then
        # Try to update cancelled order (should fail)
        AFTER_CANCEL='{"status": "PAID"}'
        response=$(make_request_with_retry "PUT" "$BASE_URL/orders/$CANCEL_ORDER_ID/status" "$AFTER_CANCEL")
        http_code=$(echo "$response" | tail -1)
        body=$(echo "$response" | sed '$d')
        check_status "400" "$http_code" "Update cancelled order" "$body"
    fi
else
    ((TESTS_FAILED++))
fi

echo ""
echo "12. Cleaning Up Test Orders"
echo "---------------------------"
# Delete the main test order
response=$(make_request_with_retry "DELETE" "$BASE_URL/orders/$ORDER_ID" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "204" "$http_code" "Delete main test order" "$body"

# Delete the cancelled order if it exists
if [ ! -z "$CANCEL_ORDER_ID" ]; then
    response=$(make_request_with_retry "DELETE" "$BASE_URL/orders/$CANCEL_ORDER_ID" "")
    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')
    check_status "204" "$http_code" "Delete cancelled order" "$body"
fi

echo ""
echo "13. Verifying Cleanup"
echo "---------------------"
response=$(make_request_with_retry "GET" "$BASE_URL/orders/$ORDER_ID" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "404" "$http_code" "Verify main order deleted" "$body"

echo ""
echo "================================="
echo "Test Summary"
echo "================================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed!${NC}"
    exit 1
fi