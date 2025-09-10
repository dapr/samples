#!/bin/bash

# Script to perform sanity check on Product Service APIs
# Usage: ./test-apis.sh [base_url]

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common/setup/common-utils.sh"

# Use provided base URL or default to localhost
BASE_URL="${1:-http://localhost/products-service}"

echo "Product Service API Sanity Check"
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
echo "2. Creating Test Product"
echo "------------------------"
TEST_PRODUCT='{
    "productId": 9999,
    "productName": "Test Product",
    "productDescription": "This is a test product",
    "stockOnHand": 100,
    "lowStockThreshold": 20
}'

response=$(make_request_with_retry "POST" "$BASE_URL/products" "$TEST_PRODUCT")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
    PRODUCT_ID=9999
    if [ "$http_code" = "201" ]; then
        print_test_result "Create product" "true"
        echo "  Created product with ID: $PRODUCT_ID"
    else
        print_test_result "Create/Update product" "true"
        echo "  Created/Updated product with ID: $PRODUCT_ID"
    fi
    ((TESTS_PASSED++))
else
    print_test_result "Create product" "false" "Expected HTTP 201 or 200, got $http_code. Response: $body"
    ((TESTS_FAILED++))
    echo "Failed to create product. Stopping tests."
    exit 1
fi

echo ""
echo "3. Getting Created Product"
echo "--------------------------"
response=$(make_request_with_retry "GET" "$BASE_URL/products/$PRODUCT_ID" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "200" "$http_code" "Get product" "$body"; then
    # Verify the product data
    if echo "$body" | grep -q "Test Product" && echo "$body" | grep -q '"stockOnHand":100'; then
        print_test_result "Verify product data" "true"
        ((TESTS_PASSED++))
    else
        print_test_result "Verify product data" "false" "Product data doesn't match expected values"
        ((TESTS_FAILED++))
    fi
fi

echo ""
echo "4. Updating Product (Creating with existing ID)"
echo "-----------------------------------------------"
UPDATE_PRODUCT='{
    "productId": 9999,
    "productName": "Updated Test Product",
    "productDescription": "This is an updated test product",
    "stockOnHand": 150,
    "lowStockThreshold": 30
}'

response=$(make_request_with_retry "POST" "$BASE_URL/products" "$UPDATE_PRODUCT")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "200" "$http_code" "Update product (via POST)" "$body"; then
    # Verify the update
    if echo "$body" | grep -q "Updated Test Product" && echo "$body" | grep -q '"stockOnHand":150'; then
        print_test_result "Verify updated data" "true"
        ((TESTS_PASSED++))
    else
        print_test_result "Verify updated data" "false" "Updated data doesn't match expected values"
        ((TESTS_FAILED++))
    fi
fi

echo ""
echo "5. Testing Stock Decrement"
echo "--------------------------"
STOCK_UPDATE='{"quantity": 10}'

response=$(make_request_with_retry "PUT" "$BASE_URL/products/$PRODUCT_ID/decrement" "$STOCK_UPDATE")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "200" "$http_code" "Decrement stock" "$body"; then
    # Verify the stock was decremented
    if echo "$body" | grep -q '"stockOnHand":140'; then
        print_test_result "Verify stock decrement" "true"
        ((TESTS_PASSED++))
    else
        print_test_result "Verify stock decrement" "false" "Stock not decremented correctly"
        ((TESTS_FAILED++))
    fi
fi

echo ""
echo "6. Testing Stock Increment"
echo "--------------------------"
response=$(make_request_with_retry "PUT" "$BASE_URL/products/$PRODUCT_ID/increment" "$STOCK_UPDATE")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "200" "$http_code" "Increment stock" "$body"; then
    # Verify the stock was incremented
    if echo "$body" | grep -q '"stockOnHand":150'; then
        print_test_result "Verify stock increment" "true"
        ((TESTS_PASSED++))
    else
        print_test_result "Verify stock increment" "false" "Stock not incremented correctly"
        ((TESTS_FAILED++))
    fi
fi

echo ""
echo "7. Testing Low Stock Flag"
echo "-------------------------"
# Update product to have low stock
LOW_STOCK_PRODUCT='{
    "productId": 9999,
    "productName": "Low Stock Test Product",
    "productDescription": "Testing low stock flag",
    "stockOnHand": 25,
    "lowStockThreshold": 30
}'

response=$(make_request_with_retry "POST" "$BASE_URL/products" "$LOW_STOCK_PRODUCT")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "200" "$http_code" "Update to low stock" "$body"; then
    # Verify low stock flag
    if echo "$body" | grep -q '"isLowStock":true'; then
        print_test_result "Verify low stock flag" "true"
        ((TESTS_PASSED++))
    else
        print_test_result "Verify low stock flag" "false" "Low stock flag not set correctly"
        ((TESTS_FAILED++))
    fi
fi

echo ""
echo "8. Testing Insufficient Stock Decrement"
echo "---------------------------------------"
LARGE_DECREMENT='{"quantity": 100}'

response=$(make_request_with_retry "PUT" "$BASE_URL/products/$PRODUCT_ID/decrement" "$LARGE_DECREMENT")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "400" "$http_code" "Insufficient stock error" "$body"

echo ""
echo "9. Testing 404 for Non-existent Product"
echo "----------------------------------------"
response=$(make_request_with_retry "GET" "$BASE_URL/products/999999999" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "404" "$http_code" "Get non-existent product" "$body"

echo ""
echo "10. Cleaning Up Test Product"
echo "----------------------------"
response=$(make_request_with_retry "DELETE" "$BASE_URL/products/$PRODUCT_ID" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "204" "$http_code" "Delete test product" "$body"

echo ""
echo "11. Verifying Cleanup"
echo "---------------------"
response=$(make_request_with_retry "GET" "$BASE_URL/products/$PRODUCT_ID" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "404" "$http_code" "Verify product deleted" "$body"

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