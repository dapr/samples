#!/bin/bash

# Script to perform sanity check on Reviews Service APIs
# Usage: ./test-apis.sh [base_url]

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common/setup/common-utils.sh"

# Use provided base URL or default to localhost
BASE_URL="${1:-http://localhost/reviews-service}"

echo "Reviews Service API Sanity Check"
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
echo "2. Creating Test Review"
echo "-----------------------"
TEST_REVIEW='{
    "productId": 1001,
    "customerId": 999,
    "rating": 5,
    "reviewText": "This is a test review"
}'

response=$(make_request_with_retry "POST" "$BASE_URL/reviews" "$TEST_REVIEW")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "201" "$http_code" "Create review" "$body"; then
    REVIEW_ID=$(echo "$body" | grep -o '"reviewId":[0-9]*' | cut -d':' -f2)
    echo "  Created review with ID: $REVIEW_ID"
else
    echo "Failed to create review. Stopping tests."
    exit 1
fi

echo ""
echo "3. Getting Created Review"
echo "-------------------------"
response=$(make_request_with_retry "GET" "$BASE_URL/reviews/$REVIEW_ID" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "200" "$http_code" "Get review" "$body"; then
    # Verify the review data
    if echo "$body" | grep -q '"productId":1001' && echo "$body" | grep -q '"customerId":999' && echo "$body" | grep -q '"rating":5'; then
        print_test_result "Verify review data" "true"
        ((TESTS_PASSED++))
    else
        print_test_result "Verify review data" "false" "Review data doesn't match expected values"
        ((TESTS_FAILED++))
    fi
fi

echo ""
echo "4. Updating Review"
echo "------------------"
UPDATE_REVIEW='{
    "rating": 4,
    "reviewText": "Updated test review - actually it was just okay"
}'

response=$(make_request_with_retry "PUT" "$BASE_URL/reviews/$REVIEW_ID" "$UPDATE_REVIEW")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "200" "$http_code" "Update review" "$body"; then
    # Verify the update
    if echo "$body" | grep -q '"rating":4' && echo "$body" | grep -q "Updated test review"; then
        print_test_result "Verify updated data" "true"
        ((TESTS_PASSED++))
    else
        print_test_result "Verify updated data" "false" "Updated data doesn't match expected values"
        ((TESTS_FAILED++))
    fi
    
    # Verify productId and customerId didn't change
    if echo "$body" | grep -q '"productId":1001' && echo "$body" | grep -q '"customerId":999'; then
        print_test_result "Verify immutable fields" "true"
        ((TESTS_PASSED++))
    else
        print_test_result "Verify immutable fields" "false" "Product ID or Customer ID changed unexpectedly"
        ((TESTS_FAILED++))
    fi
fi

echo ""
echo "5. Testing Empty Review Text"
echo "----------------------------"
EMPTY_TEXT_REVIEW='{
    "rating": 3,
    "reviewText": ""
}'

response=$(make_request_with_retry "PUT" "$BASE_URL/reviews/$REVIEW_ID" "$EMPTY_TEXT_REVIEW")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "200" "$http_code" "Update with empty text" "$body"; then
    # Verify empty text becomes empty string
    if echo "$body" | grep -q '"reviewText":""'; then
        print_test_result "Verify empty text handling" "true"
        ((TESTS_PASSED++))
    else
        print_test_result "Verify empty text handling" "false" "Empty text not converted to empty string"
        echo "  DEBUG: Response body: $body"
        ((TESTS_FAILED++))
    fi
fi

echo ""
echo "6. Testing Invalid Rating"
echo "-------------------------"
INVALID_RATING='{"rating": 6}'

response=$(make_request_with_retry "PUT" "$BASE_URL/reviews/$REVIEW_ID" "$INVALID_RATING")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "422" "$http_code" "Invalid rating (>5)" "$body"

INVALID_RATING='{"rating": 0}'
response=$(make_request_with_retry "PUT" "$BASE_URL/reviews/$REVIEW_ID" "$INVALID_RATING")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "422" "$http_code" "Invalid rating (<1)" "$body"

echo ""
echo "7. Testing 404 for Non-existent Review"
echo "---------------------------------------"
response=$(make_request_with_retry "GET" "$BASE_URL/reviews/999999999" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "404" "$http_code" "Get non-existent review" "$body"

echo ""
echo "8. Creating Review Without Text"
echo "--------------------------------"
NO_TEXT_REVIEW='{
    "productId": 1002,
    "customerId": 998,
    "rating": 4
}'

response=$(make_request_with_retry "POST" "$BASE_URL/reviews" "$NO_TEXT_REVIEW")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')

if check_status "201" "$http_code" "Create review without text" "$body"; then
    NO_TEXT_REVIEW_ID=$(echo "$body" | grep -o '"reviewId":[0-9]*' | cut -d':' -f2)
    if echo "$body" | grep -q '"reviewText":""'; then
        print_test_result "Verify empty text in response" "true"
        ((TESTS_PASSED++))
    else
        print_test_result "Verify empty text in response" "false" "Review text should be empty string"
        echo "  DEBUG: Response body: $body"
        ((TESTS_FAILED++))
    fi
fi

echo ""
echo "9. Deleting Test Reviews"
echo "------------------------"
response=$(make_request_with_retry "DELETE" "$BASE_URL/reviews/$REVIEW_ID" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "204" "$http_code" "Delete first review" "$body"

if [ ! -z "$NO_TEXT_REVIEW_ID" ]; then
    response=$(make_request_with_retry "DELETE" "$BASE_URL/reviews/$NO_TEXT_REVIEW_ID" "")
    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | sed '$d')
    check_status "204" "$http_code" "Delete second review" "$body"
fi

echo ""
echo "10. Verifying Deletion"
echo "----------------------"
response=$(make_request_with_retry "GET" "$BASE_URL/reviews/$REVIEW_ID" "")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$d')
check_status "404" "$http_code" "Get deleted review" "$body"

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