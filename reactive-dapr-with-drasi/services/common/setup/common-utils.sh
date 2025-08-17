#!/bin/bash

# Common utilities for service setup and testing scripts

# Colors for output
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

# Function to make HTTP request with retries
make_request_with_retry() {
    local method="$1"
    local url="$2"
    local data="$3"
    local max_retries="${4:-3}"  # Default to 3 retries
    local retry_delay="${5:-2}"   # Default to 2 second delay
    
    for i in $(seq 1 $max_retries); do
        if [ "$method" = "GET" ]; then
            response=$(curl -s -w "\n%{http_code}" "$url" 2>&1)
        elif [ "$method" = "POST" ]; then
            response=$(curl -s -w "\n%{http_code}" -X POST "$url" \
                -H "Content-Type: application/json" \
                -d "$data" 2>&1)
        elif [ "$method" = "PUT" ]; then
            response=$(curl -s -w "\n%{http_code}" -X PUT "$url" \
                -H "Content-Type: application/json" \
                -d "$data" 2>&1)
        elif [ "$method" = "DELETE" ]; then
            response=$(curl -s -w "\n%{http_code}" -X DELETE "$url" 2>&1)
        fi
        
        # Check if curl succeeded
        if [ $? -eq 0 ]; then
            # Extract HTTP code from response
            http_code=$(echo "$response" | tail -1)
            
            # Check if we got a valid HTTP response code
            if [[ "$http_code" =~ ^[0-9]+$ ]]; then
                # Don't retry on client errors (4xx) or success (2xx, 3xx)
                if [ "$http_code" -lt 500 ]; then
                    echo "$response"
                    return 0
                fi
                
                # For 500+ errors, only retry on specific transient errors
                if [ "$http_code" -eq 500 ] || [ "$http_code" -eq 502 ] || [ "$http_code" -eq 503 ] || [ "$http_code" -eq 504 ]; then
                    # Check if it's a transient error by looking at the response body
                    body=$(echo "$response" | sed '$d')
                    if echo "$body" | grep -q "Socket closed\|UNAVAILABLE\|Connection refused\|timeout"; then
                        # This is a transient error, continue with retry
                        :
                    else
                        # Non-transient 500 error, don't retry
                        echo "$response"
                        return 0
                    fi
                else
                    # Other 5xx error, return without retry
                    echo "$response"
                    return 0
                fi
            fi
        fi
        
        # Log retry attempt
        if [ $i -lt $max_retries ]; then
            print_warning "  Retry $i/$max_retries: Request failed, retrying in ${retry_delay}s..." >&2
            sleep $retry_delay
        fi
    done
    
    # Return the last response even if all retries failed
    echo "$response"
    return 1
}

# Function to wait for service to be ready
wait_for_service() {
    local service_url="$1"
    local max_wait="${2:-30}"  # Default to 30 seconds
    local check_interval="${3:-2}"  # Default to 2 second intervals
    
    print_info "Waiting for service at $service_url to be ready..."
    
    local elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        response=$(make_request_with_retry "GET" "$service_url/health" "" 1 0)
        http_code=$(echo "$response" | tail -1)
        
        if [[ "$http_code" =~ ^[0-9]+$ ]] && [ "$http_code" -eq 200 ]; then
            print_success "Service is ready!"
            return 0
        fi
        
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
        echo -n "."
    done
    
    echo ""
    print_error "Service did not become ready within ${max_wait} seconds"
    return 1
}

# Function to print test result (for test scripts)
print_test_result() {
    local test_name="$1"
    local success="$2"
    local message="$3"
    
    if [ "$success" = "true" ]; then
        echo -e "✓ ${GREEN}PASS${NC}: $test_name"
    else
        echo -e "✗ ${RED}FAIL${NC}: $test_name"
        [ -n "$message" ] && echo "  Error: $message"
    fi
}

# Function to check HTTP status code (for test scripts)
check_http_status() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    local body="$4"
    
    if [ "$actual" = "$expected" ]; then
        print_test_result "$test_name" "true"
        return 0
    else
        print_test_result "$test_name" "false" "Expected HTTP $expected, got $actual. Response: $body"
        return 1
    fi
}

# Function to generate random ID
generate_random_id() {
    echo $((RANDOM * RANDOM % 1000000))
}

# Function to generate random email
generate_random_email() {
    local prefix="${1:-test}"
    echo "${prefix}.$(generate_random_id)@example.com"
}