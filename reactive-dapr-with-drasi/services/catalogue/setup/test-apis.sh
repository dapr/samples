#!/bin/bash

# Script to perform sanity check on Catalogue Service APIs
# Usage: ./test-apis.sh [base_url]

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common/setup/common-utils.sh"

# Use provided base URL or default to localhost
BASE_URL="${1:-http://localhost/catalogue-service}"

echo "Catalogue Service API Sanity Check"
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

echo ""
echo "Testing Catalogue Service APIs"
echo "=============================="

# Test 1: Health Check
echo ""
echo "Test 1: Health Check"
echo "-------------------"
RESPONSE=$(make_request_with_retry "GET" "$BASE_URL/health" "")
if echo "$RESPONSE" | grep -q '"status":"healthy"'; then
    print_result "Health check" true "Service is healthy"
else
    print_result "Health check" false "Service health check failed"
fi

# Test 2: List All Catalogue Items
echo ""
echo "Test 2: List All Catalogue Items"
echo "--------------------------------"
RESPONSE=$(make_request_with_retry "GET" "$BASE_URL/catalogue" "")
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
if [ "$HTTP_CODE" = "200" ]; then
    print_result "List all items" true "Successfully retrieved catalogue list"
else
    print_result "List all items" false "Expected 200, got: $HTTP_CODE"
fi

# Test 3: Get Product Catalogue (Product 1001)
echo ""
echo "Test 3: Get Product Catalogue - Product 1001"
echo "--------------------------------------------"
RESPONSE=$(make_request_with_retry "GET" "$BASE_URL/catalogue/1001" "")
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
if [ "$HTTP_CODE" = "200" ]; then
    print_result "Get product 1001" true "Product catalogue retrieved"
elif [ "$HTTP_CODE" = "404" ]; then
    print_result "Get product 1001" true "Product not found (expected if Drasi hasn't populated data)"
else
    print_result "Get product 1001" false "Unexpected response code: $HTTP_CODE"
fi

# Print summary
echo ""
echo "================================="
echo "Test Summary"
echo "================================="
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
else
    echo -e "${RED}Some tests failed!${NC}"
fi

echo ""
echo "Note: The catalogue service is read-only and depends on data populated by Drasi."
echo "If products return 404, it's expected until:"
echo "1. The Drasi SyncStateStoreReaction is deployed and running"
echo "2. The Drasi query has processed data from products, orders, and reviews"
echo "3. The products have associated orders and reviews"

exit $TESTS_FAILED