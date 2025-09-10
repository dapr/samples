#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Base URL for services
BASE_URL="http://localhost"

# Track created entities for cleanup
CREATED_ORDERS=()
CREATED_PRODUCT=""
CREATED_CUSTOMERS=()

# Helper function to print headers
print_header() {
    echo
    echo -e "${CYAN}${BOLD}===================================================${NC}"
    echo -e "${CYAN}${BOLD}$1${NC}"
    echo -e "${CYAN}${BOLD}===================================================${NC}"
    echo
}

# Helper function to show command
show_command() {
    echo -e "${GREEN}Running command:${NC}"
    echo -e "${BOLD}$1${NC}"
    echo
}

# Helper function to execute curl with retries
execute_with_retry() {
    local cmd="$1"
    local max_retries=3
    local retry_delay=2
    
    for i in $(seq 1 $max_retries); do
        # Execute command and capture output and exit code
        output=$(eval "$cmd" 2>&1)
        exit_code=$?
        
        # Check if successful or if output contains error patterns
        if [ $exit_code -eq 0 ] && ! echo "$output" | grep -q "_InactiveRpcError\|Socket closed\|StatusCode.UNAVAILABLE"; then
            echo "$output"
            return 0
        fi
        
        # If it's not the last retry, wait before retrying
        if [ $i -lt $max_retries ]; then
            sleep $retry_delay
        fi
    done
    
    # If all retries failed, return error
    return 1
}

# Helper function to wait for user to continue
wait_for_continue() {
    local prompt="${1:-Press Enter to continue...}"
    echo -e "${YELLOW}${prompt}${NC}"
    read -p "> " response
}

# Start of demo
clear
print_header "Dashboard Service Demo - Real-time Monitoring with Drasi"
echo -e "${GREEN}This demo showcases two powerful Drasi queries in sequence:${NC}"
echo
echo -e "${CYAN}${BOLD}Part 1: Stock Risk Detection${NC}"
echo -e "${GREEN}• Demonstrates the 'at-risk-orders-query'${NC}"
echo -e "${GREEN}• Shows different severity levels based on stock shortage${NC}"
echo
echo -e "${CYAN}${BOLD}Part 2: Temporal Query Detection${NC}"
echo -e "${GREEN}• Demonstrates the 'delayed-gold-orders-query'${NC}"
echo -e "${GREEN}• Uses drasi.trueFor() to detect stuck orders${NC}"
echo
echo -e "${YELLOW}${BOLD}Dashboard URL: ${BASE_URL}/dashboard${NC}"
echo -e "${YELLOW}Please open the dashboard in your browser now!${NC}"
echo

wait_for_continue "Press Enter when you have the dashboard open..."

# Generate random IDs for all entities
PRODUCT_ID=$((RANDOM % 9000 + 1000))  # Random ID between 1000-9999
CUSTOMER_ID_1=$((RANDOM % 100 + 5000))  # Random customer ID 5000-5099
CUSTOMER_ID_2=$((RANDOM % 100 + 5100))  # Random customer ID 5100-5199
CUSTOMER_ID_3=$((RANDOM % 100 + 5200))  # Random customer ID 5200-5299
CUSTOMER_ID_4=$((RANDOM % 100 + 5300))  # Random customer ID 5300-5399

echo
echo -e "${BLUE}Generated IDs for this demo:${NC}"
echo -e "${BLUE}• Product ID: ${PRODUCT_ID}${NC}"
echo -e "${BLUE}• Customer IDs: ${CUSTOMER_ID_1}, ${CUSTOMER_ID_2}, ${CUSTOMER_ID_3}, ${CUSTOMER_ID_4}${NC}"
echo

# Stock risk scenario quantities
STOCK_ORDER_1_QTY=40  # First order quantity
STOCK_ORDER_2_QTY=60  # Second order quantity  
INITIAL_STOCK=30      # Product stock (75% of first order, 50% of second)
LOW_THRESHOLD=25      # Low stock threshold

# Temporal query scenario - separate orders
DELAY_ORDER_1_QTY=5   # Small quantities for delay demo
DELAY_ORDER_2_QTY=3   # Small quantities for delay demo

print_header "Initial Setup: Create Customers and Product"

echo -e "${CYAN}Creating four GOLD tier customers for our demonstrations.${NC}"
echo -e "${CYAN}All customers will be GOLD tier to trigger special monitoring.${NC}"
echo

wait_for_continue "Press Enter to create customers and product..."

# Create all customers
for i in 1 2 3 4; do
    CUSTOMER_VAR="CUSTOMER_ID_${i}"
    CUSTOMER_ID=${!CUSTOMER_VAR}
    
    echo
    echo -e "${GREEN}Creating Customer ${i} (ID: ${CUSTOMER_ID}, GOLD tier)...${NC}"
    
    CUSTOMER_JSON=$(cat <<EOF
{
  "customerId": ${CUSTOMER_ID},
  "customerName": "Demo Customer ${CUSTOMER_ID}",
  "email": "customer${CUSTOMER_ID}@demo.com",
  "loyaltyTier": "GOLD"
}
EOF
)
    
    TEMP_FILE=$(mktemp)
    echo "$CUSTOMER_JSON" > "$TEMP_FILE"
    output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/customers-service/customers -H 'Content-Type: application/json' -d @${TEMP_FILE}")
    rm -f "$TEMP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "$output"
        CREATED_CUSTOMERS+=($CUSTOMER_ID)
    else
        echo -e "${RED}Failed to create customer ${i}${NC}"
        exit 1
    fi
done

# Now create the product
echo
echo -e "${GREEN}Creating product ${PRODUCT_ID} with limited stock...${NC}"
echo -e "${CYAN}• Initial stock: ${INITIAL_STOCK} units${NC}"
echo -e "${CYAN}• Low stock threshold: ${LOW_THRESHOLD} units${NC}"
    
    PRODUCT_JSON=$(cat <<EOF
{
  "productId": ${PRODUCT_ID},
  "productName": "Dashboard Demo Product ${PRODUCT_ID}",
  "productDescription": "Product for demonstrating stock scenarios in dashboard",
  "stockOnHand": ${INITIAL_STOCK},
  "lowStockThreshold": ${LOW_THRESHOLD}
}
EOF
)
    
    show_command "curl -X POST ${BASE_URL}/products-service/products \\
  -H \"Content-Type: application/json\" \\
  -d '${PRODUCT_JSON}'"
    
    TEMP_FILE=$(mktemp)
    echo "$PRODUCT_JSON" > "$TEMP_FILE"
    output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/products-service/products -H 'Content-Type: application/json' -d @${TEMP_FILE}")
    rm -f "$TEMP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "$output"
        CREATED_PRODUCT=$PRODUCT_ID
    else
        echo -e "${RED}Failed to create product${NC}"
        exit 1
    fi

echo
print_header "PART 1: Demonstrating at-risk-orders-query"

echo -e "${CYAN}${BOLD}Query: at-risk-orders-query${NC}"
echo -e "${GREEN}This query detects orders where requested quantity exceeds available stock.${NC}"
echo -e "${GREEN}We'll create two orders with different shortage levels to show severity classification.${NC}"
echo

wait_for_continue "Press Enter to start Part 1..."

echo
print_header "Part 1 - Order 1: Medium/High Severity Stock Risk"

echo -e "${CYAN}Creating first order that exceeds available stock:${NC}"
echo -e "${CYAN}• Customer: ${CUSTOMER_ID_1} (GOLD tier)${NC}"
echo -e "${CYAN}• Product: ${PRODUCT_ID}${NC}"
echo -e "${CYAN}• Quantity requested: ${STOCK_ORDER_1_QTY} units${NC}"
echo -e "${CYAN}• Available stock: ${INITIAL_STOCK} units${NC}"
echo
echo -e "${YELLOW}⚠️  This creates a shortage of $((STOCK_ORDER_1_QTY - INITIAL_STOCK)) units (75% fulfillment)${NC}"
echo -e "${YELLOW}⚠️  Expected severity: MEDIUM to HIGH${NC}"
echo

wait_for_continue "Press Enter to create the first order..."

ORDER_1_ID=$((RANDOM % 9000 + 10000))  # Random order ID

echo
echo -e "${GREEN}Creating order ${ORDER_1_ID}...${NC}"
    
ORDER_1_JSON=$(cat <<EOF
{
  "orderId": ${ORDER_1_ID},
  "customerId": ${CUSTOMER_ID_1},
  "items": [
    {
      "productId": ${PRODUCT_ID},
      "quantity": ${STOCK_ORDER_1_QTY}
    }
  ],
  "status": "PENDING"
}
EOF
)
    
    show_command "curl -X POST ${BASE_URL}/orders-service/orders \\
  -H \"Content-Type: application/json\" \\
  -d '${ORDER_1_JSON}'"
    
    TEMP_FILE=$(mktemp)
    echo "$ORDER_1_JSON" > "$TEMP_FILE"
    output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/orders-service/orders -H 'Content-Type: application/json' -d @${TEMP_FILE}")
    rm -f "$TEMP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "$output"
        CREATED_ORDERS+=($ORDER_1_ID)
        echo
        echo -e "${GREEN}✓ Order ${ORDER_1_ID} created successfully!${NC}"
        echo
        echo -e "${YELLOW}${BOLD}📊 DASHBOARD CHECKPOINT #1:${NC}"
        echo -e "${GREEN}1. Go to the 'Stock Risk Orders' tab${NC}"
        echo -e "${GREEN}2. You should see Order ${ORDER_1_ID} appear immediately${NC}"
        echo -e "${GREEN}3. Note the severity level and shortage amount${NC}"
        echo
        
        wait_for_continue "Press Enter after observing the first order in the dashboard..."
        
        echo -e "${GREEN}✓ Good! Now let's create a second order with even higher shortage.${NC}"
    else
        echo -e "${RED}Failed to create order 1${NC}"
        exit 1
    fi

echo
print_header "Part 1 - Order 2: Critical Severity Stock Risk"

echo -e "${CYAN}Creating second order with even higher stock shortage:${NC}"
echo -e "${CYAN}• Customer: ${CUSTOMER_ID_2} (GOLD tier)${NC}"
echo -e "${CYAN}• Product: ${PRODUCT_ID}${NC}"
echo -e "${CYAN}• Quantity requested: ${STOCK_ORDER_2_QTY} units${NC}"
echo -e "${CYAN}• Available stock: Still only ${INITIAL_STOCK} units${NC}"
echo
echo -e "${YELLOW}⚠️  This creates a shortage of $((STOCK_ORDER_2_QTY - INITIAL_STOCK)) units (50% fulfillment)${NC}"
echo -e "${YELLOW}⚠️  Expected severity: CRITICAL or HIGH${NC}"
echo

wait_for_continue "Press Enter to create the second order..."

ORDER_2_ID=$((RANDOM % 9000 + 20000))  # Random order ID

echo
echo -e "${GREEN}Creating order ${ORDER_2_ID}...${NC}"
    
ORDER_2_JSON=$(cat <<EOF
{
  "orderId": ${ORDER_2_ID},
  "customerId": ${CUSTOMER_ID_2},
  "items": [
    {
      "productId": ${PRODUCT_ID},
      "quantity": ${STOCK_ORDER_2_QTY}
    }
  ],
  "status": "PENDING"
}
EOF
)
    
    show_command "curl -X POST ${BASE_URL}/orders-service/orders \\
  -H \"Content-Type: application/json\" \\
  -d '${ORDER_2_JSON}'"
    
    TEMP_FILE=$(mktemp)
    echo "$ORDER_2_JSON" > "$TEMP_FILE"
    output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/orders-service/orders -H 'Content-Type: application/json' -d @${TEMP_FILE}")
    rm -f "$TEMP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "$output"
        CREATED_ORDERS+=($ORDER_2_ID)
        echo
        echo -e "${GREEN}✓ Order ${ORDER_2_ID} created successfully!${NC}"
        echo
        echo -e "${YELLOW}${BOLD}📊 DASHBOARD CHECKPOINT #2:${NC}"
        echo -e "${GREEN}1. Stay in the 'Stock Risk Orders' tab${NC}"
        echo -e "${GREEN}2. You should now see TWO orders with different severities:${NC}"
        echo -e "${GREEN}   • Order ${ORDER_1_ID}: Shortage of $((STOCK_ORDER_1_QTY - INITIAL_STOCK)) units${NC}"
        echo -e "${GREEN}   • Order ${ORDER_2_ID}: Shortage of $((STOCK_ORDER_2_QTY - INITIAL_STOCK)) units${NC}"
        echo -e "${GREEN}3. Notice the different severity levels based on shortage percentage${NC}"
        echo
        
        wait_for_continue "Press Enter after comparing both orders in the dashboard..."
        
        echo -e "${GREEN}✓ Excellent! Part 1 complete - at-risk-orders-query demonstrated!${NC}"
    else
        echo -e "${RED}Failed to create order 2${NC}"
        exit 1
    fi

echo
print_header "PART 2: Demonstrating delayed-gold-orders-query"

echo -e "${CYAN}${BOLD}Query: delayed-gold-orders-query${NC}"
echo -e "${GREEN}This query uses the temporal function: drasi.trueFor(o.orderStatus = 'PROCESSING', duration({seconds: 10}))${NC}"
echo -e "${GREEN}It detects GOLD customer orders stuck in PROCESSING state for more than 10 seconds.${NC}"
echo -e "${GREEN}We'll create two separate orders and update them to PROCESSING to trigger this query.${NC}"
echo

wait_for_continue "Press Enter to start Part 2..."

echo
print_header "Part 2 - Delayed Order 1"

echo -e "${CYAN}Creating first order for temporal query demonstration:${NC}"
echo -e "${CYAN}• Customer: ${CUSTOMER_ID_3} (GOLD tier)${NC}"
echo -e "${CYAN}• Product: ${PRODUCT_ID}${NC}"
echo -e "${CYAN}• Quantity: ${DELAY_ORDER_1_QTY} units (small quantity, no stock issue)${NC}"
echo

wait_for_continue "Press Enter to create the order..."

DELAY_ORDER_1_ID=$((RANDOM % 9000 + 30000))  # Random order ID

echo
echo -e "${GREEN}Creating order ${DELAY_ORDER_1_ID}...${NC}"

DELAY_ORDER_1_JSON=$(cat <<EOF
{
  "orderId": ${DELAY_ORDER_1_ID},
  "customerId": ${CUSTOMER_ID_3},
  "items": [
    {
      "productId": ${PRODUCT_ID},
      "quantity": ${DELAY_ORDER_1_QTY}
    }
  ],
  "status": "PENDING"
}
EOF
)

show_command "curl -X POST ${BASE_URL}/orders-service/orders \\
  -H \"Content-Type: application/json\" \\
  -d '${DELAY_ORDER_1_JSON}'"
    
TEMP_FILE=$(mktemp)
echo "$DELAY_ORDER_1_JSON" > "$TEMP_FILE"
output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/orders-service/orders -H 'Content-Type: application/json' -d @${TEMP_FILE}")
rm -f "$TEMP_FILE"

if [ $? -eq 0 ]; then
    echo "$output"
    CREATED_ORDERS+=($DELAY_ORDER_1_ID)
    echo
    echo -e "${GREEN}✓ Order ${DELAY_ORDER_1_ID} created successfully!${NC}"
    
    # Now update it to PROCESSING
    echo
    echo -e "${YELLOW}Now updating order ${DELAY_ORDER_1_ID} to PROCESSING status...${NC}"
    echo -e "${YELLOW}The temporal query will trigger after 10 seconds.${NC}"
    echo
    
    UPDATE_JSON='{"status": "PROCESSING"}'
    
    show_command "curl -X PUT ${BASE_URL}/orders-service/orders/${DELAY_ORDER_1_ID}/status \\
  -H \"Content-Type: application/json\" \\
  -d '${UPDATE_JSON}'"
    
    TEMP_FILE=$(mktemp)
    echo "$UPDATE_JSON" > "$TEMP_FILE"
    output=$(execute_with_retry "curl -s -X PUT ${BASE_URL}/orders-service/orders/${DELAY_ORDER_1_ID}/status -H 'Content-Type: application/json' -d @${TEMP_FILE}")
    rm -f "$TEMP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "$output"
        echo
        echo -e "${GREEN}✓ Order ${DELAY_ORDER_1_ID} status updated to PROCESSING!${NC}"
        echo
        echo -e "${YELLOW}${BOLD}📊 DASHBOARD CHECKPOINT #3 (Time-sensitive):${NC}"
        echo -e "${GREEN}1. Switch to the 'Gold Customer Delays' tab${NC}"
        echo -e "${GREEN}2. Wait approximately 10-12 seconds${NC}"
        echo -e "${GREEN}3. Order ${DELAY_ORDER_1_ID} will appear after 10 seconds${NC}"
        echo -e "${GREEN}4. Notice the live duration counter incrementing${NC}"
        echo
        
        wait_for_continue "Press Enter after seeing order ${DELAY_ORDER_1_ID} appear in 'Gold Customer Delays'..."
        
        echo -e "${GREEN}✓ Great! Now let's add a second delayed order.${NC}"
    else
        echo -e "${RED}Failed to update order status${NC}"
        exit 1
    fi
else
    echo -e "${RED}Failed to create delay order 1${NC}"
    exit 1
fi

echo
print_header "Part 2 - Delayed Order 2"

echo -e "${CYAN}Creating second order for temporal query demonstration:${NC}"
echo -e "${CYAN}• Customer: ${CUSTOMER_ID_4} (GOLD tier)${NC}"
echo -e "${CYAN}• Product: ${PRODUCT_ID}${NC}"
echo -e "${CYAN}• Quantity: ${DELAY_ORDER_2_QTY} units (small quantity, no stock issue)${NC}"
echo

wait_for_continue "Press Enter to create and update the second order..."

DELAY_ORDER_2_ID=$((RANDOM % 9000 + 40000))  # Random order ID

echo
echo -e "${GREEN}Creating order ${DELAY_ORDER_2_ID}...${NC}"

DELAY_ORDER_2_JSON=$(cat <<EOF
{
  "orderId": ${DELAY_ORDER_2_ID},
  "customerId": ${CUSTOMER_ID_4},
  "items": [
    {
      "productId": ${PRODUCT_ID},
      "quantity": ${DELAY_ORDER_2_QTY}
    }
  ],
  "status": "PENDING"
}
EOF
)

TEMP_FILE=$(mktemp)
echo "$DELAY_ORDER_2_JSON" > "$TEMP_FILE"
output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/orders-service/orders -H 'Content-Type: application/json' -d @${TEMP_FILE}")
rm -f "$TEMP_FILE"

if [ $? -eq 0 ]; then
    echo "$output"
    CREATED_ORDERS+=($DELAY_ORDER_2_ID)
    echo
    echo -e "${GREEN}✓ Order ${DELAY_ORDER_2_ID} created!${NC}"
    
    # Update to PROCESSING
    echo
    echo -e "${YELLOW}Updating order ${DELAY_ORDER_2_ID} to PROCESSING...${NC}"
    
    TEMP_FILE=$(mktemp)
    echo "$UPDATE_JSON" > "$TEMP_FILE"
    output=$(execute_with_retry "curl -s -X PUT ${BASE_URL}/orders-service/orders/${DELAY_ORDER_2_ID}/status -H 'Content-Type: application/json' -d @${TEMP_FILE}")
    rm -f "$TEMP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "$output"
        echo
        echo -e "${GREEN}✓ Order ${DELAY_ORDER_2_ID} status updated to PROCESSING!${NC}"
        echo
        echo -e "${YELLOW}${BOLD}📊 DASHBOARD CHECKPOINT #4 (Time-sensitive):${NC}"
        echo -e "${GREEN}1. Stay in the 'Gold Customer Delays' tab${NC}"
        echo -e "${GREEN}2. Wait approximately 10-12 seconds${NC}"
        echo -e "${GREEN}3. Order ${DELAY_ORDER_2_ID} will appear after 10 seconds${NC}"
        echo -e "${GREEN}4. You'll now see TWO orders with live duration counters${NC}"
        echo
        
        wait_for_continue "Press Enter after seeing both delayed orders in the dashboard..."
        
        echo -e "${GREEN}✓ Perfect! Part 2 complete - delayed-gold-orders-query demonstrated!${NC}"
    else
        echo -e "${RED}Failed to update order 2 status${NC}"
        exit 1
    fi
else
    echo -e "${RED}Failed to create delay order 2${NC}"
    exit 1
fi

echo
print_header "Demo Complete!"

echo -e "${GREEN}${BOLD}Summary of What You Demonstrated:${NC}"
echo

echo -e "${CYAN}${BOLD}Part 1: at-risk-orders-query${NC}"
echo -e "${GREEN}✓ Created 2 orders with different stock shortages${NC}"
echo -e "${GREEN}✓ Observed immediate detection of stock risks${NC}"
echo -e "${GREEN}✓ Saw different severity levels based on shortage percentage${NC}"
echo -e "${GREEN}  • Order ${ORDER_1_ID}: $((STOCK_ORDER_1_QTY - INITIAL_STOCK)) units short (75% fulfillment)${NC}"
echo -e "${GREEN}  • Order ${ORDER_2_ID}: $((STOCK_ORDER_2_QTY - INITIAL_STOCK)) units short (50% fulfillment)${NC}"

echo
echo -e "${CYAN}${BOLD}Part 2: delayed-gold-orders-query${NC}"
echo -e "${GREEN}✓ Created 2 orders and set them to PROCESSING${NC}"
echo -e "${GREEN}✓ Observed temporal query triggering after 10 seconds${NC}"
echo -e "${GREEN}✓ Saw live duration counters for stuck orders${NC}"
echo -e "${GREEN}  • Order ${DELAY_ORDER_1_ID}: Detected after 10+ seconds in PROCESSING${NC}"
echo -e "${GREEN}  • Order ${DELAY_ORDER_2_ID}: Detected after 10+ seconds in PROCESSING${NC}"

echo
echo -e "${YELLOW}${BOLD}Key Drasi Capabilities Demonstrated:${NC}"
echo -e "${CYAN}✓ Real-time change detection via CDC${NC}"
echo -e "${CYAN}✓ Complex joins across multiple data sources${NC}"
echo -e "${CYAN}✓ Temporal functions (drasi.trueFor) without polling${NC}"
echo -e "${CYAN}✓ Push-based updates via SignalR${NC}"
echo -e "${CYAN}✓ Severity classification and business logic in queries${NC}"
echo -e "${CYAN}✓ Event-driven architecture with zero polling${NC}"

echo
echo -e "${GREEN}${BOLD}This demonstrates how Drasi empowers Dapr applications with:${NC}"
echo -e "${GREEN}• Real-time monitoring and alerting${NC}"
echo -e "${GREEN}• Complex event processing${NC}"
echo -e "${GREEN}• Time-based condition detection${NC}"
echo -e "${GREEN}• Live dashboards without polling${NC}"

echo
echo -e "${BOLD}${YELLOW}Thank you for exploring Drasi's real-time capabilities!${NC}"
echo

# Cleanup section
print_header "Optional: Clean Up Demo Data"

echo -e "${CYAN}Would you like to clean up all the demo data created?${NC}"
echo -e "${CYAN}This will delete:${NC}"
echo -e "${CYAN}• ${#CREATED_ORDERS[@]} orders${NC}"
if [ ${#CREATED_ORDERS[@]} -gt 0 ]; then
    echo -e "${CYAN}  IDs: ${CREATED_ORDERS[@]}${NC}"
fi
if [ ! -z "$CREATED_PRODUCT" ]; then
    echo -e "${CYAN}• 1 product (ID: ${CREATED_PRODUCT})${NC}"
fi
echo -e "${CYAN}• ${#CREATED_CUSTOMERS[@]} customers${NC}"
if [ ${#CREATED_CUSTOMERS[@]} -gt 0 ]; then
    echo -e "${CYAN}  IDs: ${CREATED_CUSTOMERS[@]}${NC}"
fi
echo

echo -e "${YELLOW}Note: Cleanup allows you to run this demo again with a clean environment.${NC}"
echo

# Ask if user wants to cleanup
echo -e "${YELLOW}Do you want to clean up the demo data? (yes/no):${NC}"
read -p "> " cleanup_response

if [[ "$cleanup_response" =~ ^[Yy][Ee]?[Ss]?$ ]]; then
    echo
    echo -e "${GREEN}Starting cleanup...${NC}"
    echo
    
    # Track cleanup success
    cleanup_failed=false
    
    # Delete orders first (they reference products and customers)
    if [ ${#CREATED_ORDERS[@]} -gt 0 ]; then
        echo -e "${YELLOW}Deleting orders...${NC}"
        for order_id in "${CREATED_ORDERS[@]}"; do
            if [ ! -z "$order_id" ]; then
                echo -n "  Deleting order ${order_id}... "
                response=$(curl -s -X DELETE "${BASE_URL}/orders-service/orders/${order_id}" -w "\n%{http_code}" 2>/dev/null)
                http_code=$(echo "$response" | tail -1)
                
                if [ "$http_code" = "204" ] || [ "$http_code" = "404" ]; then
                    echo -e "${GREEN}✓${NC}"
                else
                    echo -e "${RED}✗ (HTTP ${http_code})${NC}"
                    cleanup_failed=true
                fi
            fi
        done
    fi
    
    # Delete product
    if [ ! -z "$CREATED_PRODUCT" ]; then
        echo
        echo -e "${YELLOW}Deleting product...${NC}"
        echo -n "  Deleting product ${CREATED_PRODUCT}... "
        response=$(curl -s -X DELETE "${BASE_URL}/products-service/products/${CREATED_PRODUCT}" -w "\n%{http_code}" 2>/dev/null)
        http_code=$(echo "$response" | tail -1)
        
        if [ "$http_code" = "204" ] || [ "$http_code" = "404" ]; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗ (HTTP ${http_code})${NC}"
            cleanup_failed=true
        fi
    fi
    
    # Delete customers
    if [ ${#CREATED_CUSTOMERS[@]} -gt 0 ]; then
        echo
        echo -e "${YELLOW}Deleting customers...${NC}"
        for customer_id in "${CREATED_CUSTOMERS[@]}"; do
            if [ ! -z "$customer_id" ]; then
                echo -n "  Deleting customer ${customer_id}... "
                response=$(curl -s -X DELETE "${BASE_URL}/customers-service/customers/${customer_id}" -w "\n%{http_code}" 2>/dev/null)
                http_code=$(echo "$response" | tail -1)
                
                if [ "$http_code" = "204" ] || [ "$http_code" = "404" ]; then
                    echo -e "${GREEN}✓${NC}"
                else
                    echo -e "${RED}✗ (HTTP ${http_code})${NC}"
                    cleanup_failed=true
                fi
            fi
        done
    fi
    
    echo
    if [ "$cleanup_failed" = true ]; then
        echo -e "${YELLOW}⚠️  Some items could not be deleted (they may have been already deleted).${NC}"
        echo -e "${YELLOW}This is normal if you've run cleanup before or items were manually deleted.${NC}"
    else
        echo -e "${GREEN}${BOLD}✓ Cleanup complete!${NC}"
        echo -e "${GREEN}All demo data has been removed. You can run this demo again.${NC}"
    fi
else
    echo
    echo -e "${YELLOW}Skipping cleanup. Demo data will remain in the system.${NC}"
    echo -e "${YELLOW}You can manually delete the entities later if needed.${NC}"
fi

echo
echo -e "${CYAN}${BOLD}Demo script finished. Goodbye!${NC}"
echo