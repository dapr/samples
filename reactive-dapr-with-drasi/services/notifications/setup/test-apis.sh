#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if kubectl port-forward is needed
SERVICE_URL="http://localhost:8001/notifications-service"

echo -e "${BLUE}Testing Notifications Service APIs${NC}"
echo -e "${BLUE}=================================${NC}\n"

# Test 1: Health Check
echo -e "${YELLOW}Test 1: Health Check${NC}"
echo "GET $SERVICE_URL/health"
RESPONSE=$(curl -s -w "\n%{http_code}" $SERVICE_URL/health)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n1)

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ Health check passed${NC}"
    echo "Response: $BODY"
else
    echo -e "${RED}✗ Health check failed (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
fi
echo

# Test 2: Get Service Info
echo -e "${YELLOW}Test 2: Get Service Info${NC}"
echo "GET $SERVICE_URL/"
RESPONSE=$(curl -s -w "\n%{http_code}" $SERVICE_URL/)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n1)

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ Service info retrieved${NC}"
    echo "Response: $BODY" | jq '.' 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}✗ Failed to get service info (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
fi
echo

# Test 3: Get Notification Status
echo -e "${YELLOW}Test 3: Get Notification Status${NC}"
echo "GET $SERVICE_URL/status"
RESPONSE=$(curl -s -w "\n%{http_code}" $SERVICE_URL/status)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n1)

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ Status retrieved successfully${NC}"
    echo "Response: $BODY" | jq '.' 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}✗ Failed to get status (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
fi
echo

# Test 4: Reset Statistics
echo -e "${YELLOW}Test 4: Reset Statistics${NC}"
echo "POST $SERVICE_URL/reset-stats"
RESPONSE=$(curl -s -X POST -w "\n%{http_code}" $SERVICE_URL/reset-stats)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n1)

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ Statistics reset successfully${NC}"
    echo "Response: $BODY"
else
    echo -e "${RED}✗ Failed to reset statistics (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
fi
echo

# Instructions for monitoring events
echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}Event Monitoring Instructions${NC}"
echo -e "${BLUE}=================================${NC}\n"

echo -e "${YELLOW}To monitor notifications in real-time:${NC}"
echo "1. Check logs: kubectl logs -l app=notifications -f"
echo "2. The service will log notifications when stock events are received"
echo ""
echo -e "${YELLOW}To trigger stock events:${NC}"
echo "1. Update product stock levels via the products service API"
echo "2. Set stock <= lowStockThreshold to trigger low stock events"
echo "3. Set stock = 0 to trigger critical stock events"
echo ""
echo -e "${YELLOW}Example commands:${NC}"
echo "# Trigger low stock event (assuming product 1 has lowStockThreshold of 10)"
echo "curl -X PUT http://localhost:8001/products-service/products/1/decrement \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"quantity\": 95}'"
echo ""
echo "# Trigger critical stock event"
echo "curl -X PUT http://localhost:8001/products-service/products/1/decrement \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"quantity\": 5}'"