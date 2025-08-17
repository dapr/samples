#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Base URL for services
BASE_URL="http://localhost"

# Track created entities for cleanup
CREATED_PRODUCTS=()
MODIFIED_PRODUCTS=()
ORIGINAL_STOCK_VALUES=()

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

# Function to get current stock for a product
get_product_stock() {
    local product_id=$1
    output=$(execute_with_retry "curl -s ${BASE_URL}/products-service/products/${product_id}")
    if [ $? -eq 0 ]; then
        # Try both camelCase and snake_case field names
        stock=$(echo "$output" | grep -o '"stockOnHand":[0-9]*' | cut -d':' -f2)
        if [ -z "$stock" ]; then
            stock=$(echo "$output" | grep -o '"stock_on_hand":[0-9]*' | cut -d':' -f2)
        fi
        if [ -z "$stock" ]; then
            echo "0"
        else
            echo "$stock"
        fi
    else
        echo "0"
    fi
}

# Function to clean up created/modified entities
cleanup() {
    echo
    print_header "Cleaning Up Demo Data"
    
    # Restore original stock values for modified products
    if [ ${#MODIFIED_PRODUCTS[@]} -gt 0 ]; then
        echo -e "${YELLOW}Restoring original stock values...${NC}"
        for i in "${!MODIFIED_PRODUCTS[@]}"; do
            product_id="${MODIFIED_PRODUCTS[$i]}"
            original_stock="${ORIGINAL_STOCK_VALUES[$i]}"
            
            echo -e "${BLUE}Restoring product ${product_id} stock to ${original_stock}...${NC}"
            
            # Get current product details first
            product_data=$(execute_with_retry "curl -s ${BASE_URL}/products-service/products/${product_id}")
            if [ $? -eq 0 ]; then
                # Extract product details and update stock (handle both camelCase and snake_case)
                product_name=$(echo "$product_data" | grep -o '"productName":"[^"]*' | cut -d'"' -f4)
                if [ -z "$product_name" ]; then
                    product_name=$(echo "$product_data" | grep -o '"product_name":"[^"]*' | cut -d'"' -f4)
                fi
                
                product_desc=$(echo "$product_data" | grep -o '"productDescription":"[^"]*' | cut -d'"' -f4)
                if [ -z "$product_desc" ]; then
                    product_desc=$(echo "$product_data" | grep -o '"product_description":"[^"]*' | cut -d'"' -f4)
                fi
                
                threshold=$(echo "$product_data" | grep -o '"lowStockThreshold":[0-9]*' | cut -d':' -f2)
                if [ -z "$threshold" ]; then
                    threshold=$(echo "$product_data" | grep -o '"low_stock_threshold":[0-9]*' | cut -d':' -f2)
                fi
                
                RESTORE_JSON=$(cat <<EOF
{
  "productId": ${product_id},
  "productName": "${product_name}",
  "productDescription": "${product_desc}",
  "stockOnHand": ${original_stock},
  "lowStockThreshold": ${threshold}
}
EOF
)
                TEMP_FILE=$(mktemp)
                echo "$RESTORE_JSON" > "$TEMP_FILE"
                output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/products-service/products -H 'Content-Type: application/json' -d @${TEMP_FILE}")
                rm -f "$TEMP_FILE"
            fi
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Product ${product_id} stock restored${NC}"
            else
                echo -e "${RED}✗ Failed to restore product ${product_id}${NC}"
            fi
        done
    fi
    
    # Delete created products
    if [ ${#CREATED_PRODUCTS[@]} -gt 0 ]; then
        echo -e "${YELLOW}Deleting created products...${NC}"
        for product_id in "${CREATED_PRODUCTS[@]}"; do
            echo -e "${BLUE}Deleting product ${product_id}...${NC}"
            output=$(execute_with_retry "curl -s -X DELETE ${BASE_URL}/products-service/products/${product_id}")
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Product ${product_id} deleted${NC}"
            else
                echo -e "${RED}✗ Failed to delete product ${product_id}${NC}"
            fi
        done
    fi
    
    echo
    echo -e "${GREEN}${BOLD}Cleanup complete!${NC}"
}

# Set up trap to cleanup on exit
trap cleanup EXIT

# Start of demo
clear
print_header "Notifications Service Demo - Real-time Stock Alerts with Drasi"

echo -e "${GREEN}This demo showcases the Drasi PostDaprPubSub reaction for inventory management:${NC}"
echo
echo -e "${CYAN}${BOLD}Part 1: Low Stock Detection${NC}"
echo -e "${GREEN}• Demonstrates the 'low-stock-event-query'${NC}"
echo -e "${GREEN}• Triggers when stock falls below threshold but above zero${NC}"
echo -e "${GREEN}• Simulates email notification to purchasing team${NC}"
echo
echo -e "${CYAN}${BOLD}Part 2: Critical Stock Detection${NC}"
echo -e "${GREEN}• Demonstrates the 'critical-stock-event-query'${NC}"
echo -e "${GREEN}• Triggers when stock reaches zero${NC}"
echo -e "${GREEN}• Simulates urgent notifications to sales and fulfillment teams${NC}"
echo
echo -e "${MAGENTA}${BOLD}How Drasi + Dapr Work Together:${NC}"
echo -e "${GREEN}1. Drasi monitors the products state store via Dapr source${NC}"
echo -e "${GREEN}2. Continuous queries detect stock conditions in real-time${NC}"
echo -e "${GREEN}3. PostDaprPubSub reaction publishes CloudEvents to Redis via Dapr${NC}"
echo -e "${GREEN}4. Events flow through Redis Streams (Dapr's pub/sub broker)${NC}"
echo -e "${GREEN}5. Notifications service subscribes using standard Dapr pub/sub APIs${NC}"
echo -e "${BLUE}   • Uses @dapr_app.subscribe decorator (Python SDK)${NC}"
echo -e "${BLUE}   • No custom integration needed - just standard Dapr!${NC}"
echo
echo -e "${YELLOW}${BOLD}Dashboard URL: ${BASE_URL}/notifications-service${NC}"
echo -e "${YELLOW}Please open the notifications dashboard in your browser now!${NC}"
echo
echo -e "${MAGENTA}${BOLD}📧 To Monitor Email Notifications:${NC}"
echo -e "${GREEN}Open a second terminal and run:${NC}"
echo -e "${BOLD}  ./demo/monitor-notifications.sh${NC}"
echo -e "${GREEN}This will display simulated email alerts as they're triggered.${NC}"
echo
echo -e "${CYAN}${BOLD}🔍 To See Redis Pub/Sub in Action:${NC}"
echo -e "${GREEN}You can inspect the Redis streams directly:${NC}"
echo -e "${BOLD}  kubectl exec -it deployment/notifications-redis -- redis-cli${NC}"
echo -e "${BOLD}  > XINFO STREAM low-stock-events${NC}"
echo -e "${BOLD}  > XINFO STREAM critical-stock-events${NC}"
echo -e "${BLUE}Note: Dapr uses Redis Streams under the hood for pub/sub${NC}"
echo

wait_for_continue "Press Enter when you have the dashboard open..."

# Generate random ID for demo product
PRODUCT_ID_1=$((RANDOM % 900 + 8000))  # Random ID between 8000-8899

echo
echo -e "${BLUE}Generated Product ID for this demo: ${PRODUCT_ID_1}${NC}"
echo

# ==================================================
# PART 1: LOW STOCK DETECTION
# ==================================================

print_header "PART 1: Demonstrating Low Stock Detection"

echo -e "${CYAN}${BOLD}Query: low-stock-event-query${NC}"
echo -e "${GREEN}This query detects: p.stockOnHand <= p.lowStockThreshold AND p.stockOnHand > 0${NC}"
echo
echo -e "${CYAN}We'll create a product with:${NC}"
echo -e "${CYAN}• Initial stock: 50 units${NC}"
echo -e "${CYAN}• Low stock threshold: 20 units${NC}"
echo -e "${CYAN}Then reduce stock to 15 units to trigger the alert${NC}"
echo

wait_for_continue "Press Enter to create the first product..."

# Create first product
echo
echo -e "${GREEN}Creating product ${PRODUCT_ID_1} (High-End Laptop)...${NC}"

PRODUCT_1_JSON=$(cat <<EOF
{
  "productId": ${PRODUCT_ID_1},
  "productName": "High-End Laptop Pro X1",
  "productDescription": "Professional grade laptop with 32GB RAM and 1TB SSD",
  "stockOnHand": 50,
  "lowStockThreshold": 20
}
EOF
)

show_command "curl -X POST ${BASE_URL}/products-service/products \\
  -H \"Content-Type: application/json\" \\
  -d '${PRODUCT_1_JSON}'"

TEMP_FILE=$(mktemp)
echo "$PRODUCT_1_JSON" > "$TEMP_FILE"
output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/products-service/products -H 'Content-Type: application/json' -d @${TEMP_FILE}")
rm -f "$TEMP_FILE"

if [ $? -eq 0 ] && ! echo "$output" | grep -q "detail"; then
    echo "$output"
    CREATED_PRODUCTS+=($PRODUCT_ID_1)
    
    # Track the original stock value for restoration later
    MODIFIED_PRODUCTS+=($PRODUCT_ID_1)
    ORIGINAL_STOCK_VALUES+=(50)  # Original stock we just created with
    
    echo
    echo -e "${GREEN}✓ Product ${PRODUCT_ID_1} created successfully!${NC}"
    echo
    echo -e "${YELLOW}${BOLD}📊 DASHBOARD CHECKPOINT #1:${NC}"
    echo -e "${GREEN}1. Check the dashboard - all counters should still be at 0${NC}"
    echo -e "${GREEN}2. No events should appear yet (stock is healthy at 50 units)${NC}"
    echo
    
    wait_for_continue "Press Enter to reduce stock below threshold..."
    
    # Reduce stock to trigger low stock alert
    echo
    echo -e "${YELLOW}Reducing stock from 50 to 15 units (below threshold of 20)...${NC}"
    echo -e "${BLUE}Using decrement endpoint to simulate sales activity${NC}"
    
    DECREMENT_JSON=$(cat <<EOF
{
  "quantity": 35
}
EOF
)
    
    show_command "curl -X PUT ${BASE_URL}/products-service/products/${PRODUCT_ID_1}/decrement \\
  -H \"Content-Type: application/json\" \\
  -d '{\"quantity\": 35}'"
    
    TEMP_FILE=$(mktemp)
    echo "$DECREMENT_JSON" > "$TEMP_FILE"
    output=$(execute_with_retry "curl -s -X PUT ${BASE_URL}/products-service/products/${PRODUCT_ID_1}/decrement -H 'Content-Type: application/json' -d @${TEMP_FILE}")
    rm -f "$TEMP_FILE"
    
    if [ $? -eq 0 ] && ! echo "$output" | grep -q "detail"; then
        echo "$output"
        echo
        echo -e "${GREEN}✓ Stock reduced to 15 units!${NC}"
        echo
        echo -e "${RED}${BOLD}🚨 LOW STOCK ALERT TRIGGERED! 🚨${NC}"
        echo
        echo -e "${YELLOW}${BOLD}📊 DASHBOARD CHECKPOINT #2:${NC}"
        echo -e "${GREEN}1. The 'Low Stock Events' counter should increment to 1${NC}"
        echo -e "${GREEN}2. A yellow event card should appear in 'Recent Events'${NC}"
        echo -e "${GREEN}3. The event shows: Product ${PRODUCT_ID_1}, Stock: 15, Threshold: 20${NC}"
        echo
        echo -e "${CYAN}${BOLD}🔄 WHAT JUST HAPPENED (Dapr Pub/Sub):${NC}"
        echo -e "${BLUE}• Drasi detected: stockOnHand (15) <= lowStockThreshold (20)${NC}"
        echo -e "${BLUE}• PostDaprPubSub reaction published to Redis topic 'low-stock-events'${NC}"
        echo -e "${BLUE}• Notifications service received via Dapr subscription${NC}"
        echo
        echo -e "${MAGENTA}${BOLD}📧 IF MONITORING NOTIFICATIONS:${NC}"
        echo -e "${GREEN}You should see a simulated email to purchasing@company.com${NC}"
        echo -e "${GREEN}with recommended actions for the purchasing team${NC}"
        echo
        
        wait_for_continue "Press Enter after observing the low stock alert..."
        
        echo -e "${GREEN}✓ Excellent! Low stock detection demonstrated!${NC}"
    else
        echo -e "${RED}Failed to decrement product stock${NC}"
        echo -e "${RED}Error: $output${NC}"
        exit 1
    fi
else
    echo "$output"
    echo -e "${RED}Failed to create product${NC}"
    echo -e "${RED}Please ensure the products service is running and accessible${NC}"
    exit 1
fi

# ==================================================
# PART 2: CRITICAL STOCK DETECTION
# ==================================================

echo
print_header "PART 2: Demonstrating Critical Stock Detection"

echo -e "${CYAN}${BOLD}Query: critical-stock-event-query${NC}"
echo -e "${GREEN}This query detects: p.stockOnHand = 0${NC}"
echo
echo -e "${CYAN}We'll use an existing product and set its stock to zero${NC}"
echo -e "${CYAN}This simulates a complete stockout scenario${NC}"
echo

# Check if product 1 exists (ID 1 is typically always present)
EXISTING_PRODUCT_ID=1
echo -e "${CYAN}Trying to use existing product ID: ${EXISTING_PRODUCT_ID}${NC}"

# Get current stock value
CURRENT_STOCK=$(get_product_stock $EXISTING_PRODUCT_ID)

# Check if we got a valid stock value
if [ -z "$CURRENT_STOCK" ] || [ "$CURRENT_STOCK" = "0" ]; then
    echo -e "${YELLOW}Product ${EXISTING_PRODUCT_ID} has no stock or doesn't exist.${NC}"
    echo -e "${YELLOW}Let's use the product we created in Part 1...${NC}"
    
    # Use the product we created in Part 1 instead
    EXISTING_PRODUCT_ID=$PRODUCT_ID_1
    CURRENT_STOCK=$(get_product_stock $EXISTING_PRODUCT_ID)
    echo -e "${BLUE}Using product ${EXISTING_PRODUCT_ID} with current stock: ${CURRENT_STOCK} units${NC}"
    
    # For Part 1 product, we already tracked its original value, so don't add it again
    SKIP_TRACKING=true
else
    echo -e "${BLUE}Current stock for product ${EXISTING_PRODUCT_ID}: ${CURRENT_STOCK} units${NC}"
    SKIP_TRACKING=false
fi

# Only track if this is a new product we haven't tracked yet
if [ "$SKIP_TRACKING" != "true" ] && [ "$CURRENT_STOCK" != "0" ] && [ -n "$CURRENT_STOCK" ]; then
    # Check if this product is already being tracked
    already_tracked=false
    for tracked_id in "${MODIFIED_PRODUCTS[@]}"; do
        if [ "$tracked_id" = "$EXISTING_PRODUCT_ID" ]; then
            already_tracked=true
            break
        fi
    done
    
    if [ "$already_tracked" = "false" ]; then
        MODIFIED_PRODUCTS+=($EXISTING_PRODUCT_ID)
        ORIGINAL_STOCK_VALUES+=($CURRENT_STOCK)
    fi
fi

wait_for_continue "Press Enter to set stock to zero (critical level)..."

# Set stock to zero to trigger critical alert
echo
echo -e "${RED}Depleting all remaining stock to 0 units (CRITICAL - OUT OF STOCK)...${NC}"
echo -e "${BLUE}Using decrement with current stock amount to simulate complete sellout${NC}"

# Ensure we have a valid quantity
if [ -z "$CURRENT_STOCK" ] || [ "$CURRENT_STOCK" = "0" ]; then
    echo -e "${RED}Error: Invalid stock quantity. Cannot proceed with critical stock demonstration.${NC}"
    echo -e "${YELLOW}Skipping to demo summary...${NC}"
else
    # Decrement by the current stock amount to reach zero
    DECREMENT_JSON=$(cat <<EOF
{
  "quantity": ${CURRENT_STOCK}
}
EOF
)

show_command "curl -X PUT ${BASE_URL}/products-service/products/${EXISTING_PRODUCT_ID}/decrement \\
  -H \"Content-Type: application/json\" \\
  -d '{\"quantity\": ${CURRENT_STOCK}}'"

    TEMP_FILE=$(mktemp)
    echo "$DECREMENT_JSON" > "$TEMP_FILE"
    output=$(execute_with_retry "curl -s -X PUT ${BASE_URL}/products-service/products/${EXISTING_PRODUCT_ID}/decrement -H 'Content-Type: application/json' -d @${TEMP_FILE}")
    rm -f "$TEMP_FILE"

    if [ $? -eq 0 ] && ! echo "$output" | grep -q "detail"; then
        echo "$output"
        echo
        echo -e "${RED}✓ Stock set to 0 units - PRODUCT IS OUT OF STOCK!${NC}"
        echo
        echo -e "${RED}${BOLD}🚨🚨 CRITICAL STOCK ALERT TRIGGERED! 🚨🚨${NC}"
        echo
        echo -e "${YELLOW}${BOLD}📊 DASHBOARD CHECKPOINT #3:${NC}"
        echo -e "${GREEN}1. The 'Critical Stock Events' counter should increment to 1${NC}"
        echo -e "${GREEN}2. A red event card should appear in 'Recent Events'${NC}"
        echo -e "${GREEN}3. The event shows: Product ${EXISTING_PRODUCT_ID} is OUT OF STOCK${NC}"
        echo
        echo -e "${CYAN}${BOLD}🔄 WHAT JUST HAPPENED (Dapr Pub/Sub):${NC}"
        echo -e "${BLUE}• Drasi detected: stockOnHand = 0 (critical condition)${NC}"
        echo -e "${BLUE}• PostDaprPubSub reaction published to Redis topic 'critical-stock-events'${NC}"
        echo -e "${BLUE}• Different topic = different severity handling${NC}"
        echo -e "${BLUE}• Notifications service processed via standard Dapr subscription${NC}"
        echo
        echo -e "${MAGENTA}${BOLD}📧 IF MONITORING NOTIFICATIONS:${NC}"
        echo -e "${GREEN}You should see TWO simulated emails:${NC}"
        echo -e "${GREEN}  • To sales@company.com - Halt all sales immediately${NC}"
        echo -e "${GREEN}  • To fulfillment@company.com - Review pending orders${NC}"
        echo -e "${GREEN}Plus automated system actions (marking out of stock, etc.)${NC}"
        echo
        
        wait_for_continue "Press Enter after observing the critical stock alert..."
        
        echo -e "${GREEN}✓ Perfect! Critical stock detection demonstrated!${NC}"
    else
        echo -e "${RED}Failed to decrement product stock to zero${NC}"
        echo -e "${RED}Error: $output${NC}"
        exit 1
    fi
fi

# ==================================================
# DEMO SUMMARY
# ==================================================

echo
print_header "Demo Summary"

echo -e "${YELLOW}${BOLD}What You've Demonstrated:${NC}"
echo
echo -e "${GREEN}✓ ${BOLD}Low Stock Detection:${NC}"
echo -e "  • Product stock fell below threshold (15 < 20)${NC}"
echo -e "  • Drasi query detected the condition instantly${NC}"
echo -e "  • PostDaprPubSub published to 'low-stock-events' topic${NC}"
echo -e "  • Notification service received event and simulated email${NC}"
echo
echo -e "${GREEN}✓ ${BOLD}Critical Stock Detection:${NC}"
echo -e "  • Product stock reached zero${NC}"
echo -e "  • Different Drasi query detected this critical condition${NC}"
echo -e "  • Published to 'critical-stock-events' topic${NC}"
echo -e "  • Triggered urgent notifications to multiple teams${NC}"
echo
echo -e "${GREEN}✓ ${BOLD}Standard Dapr Pub/Sub Integration:${NC}"
echo -e "  • Drasi published events to Redis Streams via Dapr component${NC}"
echo -e "  • Notifications service subscribed using @dapr_app.subscribe${NC}"
echo -e "  • No custom integration - just standard Dapr pub/sub APIs${NC}"
echo -e "  • CloudEvents format ensures compatibility${NC}"
echo

echo -e "${CYAN}${BOLD}Key Takeaways for Dapr Users:${NC}"
echo -e "${GREEN}• Drasi adds sophisticated change detection to your Dapr apps${NC}"
echo -e "${GREEN}• No need to write custom monitoring code${NC}"
echo -e "${GREEN}• Leverages existing Dapr pub/sub infrastructure${NC}"
echo -e "${GREEN}• Declarative queries instead of imperative logic${NC}"
echo -e "${GREEN}• Perfect for event-driven microservices architectures${NC}"
echo

wait_for_continue "Press Enter to complete the demo and cleanup..."

echo
print_header "Demo Complete!"

echo -e "${GREEN}${BOLD}You've successfully demonstrated:${NC}"
echo -e "${GREEN}✓ Low stock detection and alerts${NC}"
echo -e "${GREEN}✓ Critical stock detection with urgent notifications${NC}"
echo -e "${GREEN}✓ Real-time event processing via Drasi + Dapr${NC}"
echo -e "${GREEN}✓ WebSocket-based dashboard updates${NC}"
echo -e "${GREEN}✓ Email simulation for different alert types${NC}"
echo
echo -e "${CYAN}${BOLD}This showcases how Drasi enhances Dapr applications by:${NC}"
echo -e "${GREEN}• Adding sophisticated change detection without custom code${NC}"
echo -e "${GREEN}• Enabling declarative business rules through queries${NC}"
echo -e "${GREEN}• Providing seamless integration with Dapr building blocks${NC}"
echo
echo -e "${YELLOW}Cleaning up demo data...${NC}"

# Cleanup will be called automatically via trap