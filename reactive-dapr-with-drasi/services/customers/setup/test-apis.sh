#!/bin/bash

# Script to perform sanity check on Customer Service APIs
# Usage: ./test-apis.sh [base_url]

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common/setup/common-utils.sh"

# Use provided base URL or default to localhost
BASE_URL="${1:-http://localhost/customers-service}"

echo "Customer Service API Sanity Check"
echo "================================="
echo "Base URL: $BASE_URL"
echo ""

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test result with counter
print_result() {
    local test_name="$1"
    local success="$2"
    local message="$3"
    
    print_test_result "$test_name" "$success" "$message"
    
    if [ "$success" = "true" ]; then
        ((TESTS_PASSED++))
    else
        ((TESTS_FAILED++))
    fi
}

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
echo "2. Creating Test Customer"
echo "------------------------"
TEST_CUSTOMER='{
    "customerName": "Test Customer",
    "loyaltyTier": "SILVER",
    "email": "test.customer@example.com"
}'

response=$(make_request_with_retry "POST" "$BASE_URL/customers" "$TEST_CUSTOMER")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "201" "$http_code" "Create customer" "$body"; then
    CUSTOMER_ID=$(echo "$body" | grep -o '"customerId":[0-9]*' | cut -d':' -f2)
    echo "  Created customer with ID: $CUSTOMER_ID"
else
    echo "Failed to create customer. Stopping tests."
    exit 1
fi

echo ""
echo "3. Getting Created Customer"
echo "--------------------------"
response=$(make_request_with_retry "GET" "$BASE_URL/customers/$CUSTOMER_ID" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "200" "$http_code" "Get customer" "$body"; then
    # Verify the customer data
    if echo "$body" | grep -q "Test Customer" && echo "$body" | grep -q "SILVER"; then
        print_result "Verify customer data" "true" ""
    else
        print_result "Verify customer data" "false" "Customer data doesn't match expected values"
    fi
fi

echo ""
echo "4. Updating Customer"
echo "-------------------"
UPDATE_DATA='{
    "customerName": "Updated Test Customer",
    "loyaltyTier": "GOLD",
    "email": "updated.test@example.com"
}'

response=$(make_request_with_retry "PUT" "$BASE_URL/customers/$CUSTOMER_ID" "$UPDATE_DATA")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "200" "$http_code" "Update customer" "$body"; then
    # Verify the update
    if echo "$body" | grep -q "Updated Test Customer" && echo "$body" | grep -q "GOLD"; then
        print_result "Verify updated data" "true" ""
    else
        print_result "Verify updated data" "false" "Updated data doesn't match expected values"
    fi
fi

echo ""
echo "5. Testing 404 for Non-existent Customer"
echo "---------------------------------------"
response=$(make_request_with_retry "GET" "$BASE_URL/customers/999999999" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "404" "$http_code" "Get non-existent customer" "$body"

echo ""
echo "6. Deleting Test Customer"
echo "------------------------"
response=$(make_request_with_retry "DELETE" "$BASE_URL/customers/$CUSTOMER_ID" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "204" "$http_code" "Delete customer" "$body"

echo ""
echo "7. Verifying Deletion"
echo "--------------------"
response=$(make_request_with_retry "GET" "$BASE_URL/customers/$CUSTOMER_ID" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "404" "$http_code" "Get deleted customer" "$body"

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