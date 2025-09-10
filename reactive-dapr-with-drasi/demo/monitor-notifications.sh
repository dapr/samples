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

clear
echo -e "${CYAN}${BOLD}===================================================${NC}"
echo -e "${CYAN}${BOLD}📧 Notifications Service Monitor${NC}"
echo -e "${CYAN}${BOLD}===================================================${NC}"
echo
echo -e "${GREEN}This window will display simulated email notifications${NC}"
echo -e "${GREEN}when stock levels trigger alerts.${NC}"
echo
echo -e "${YELLOW}Watching for:${NC}"
echo -e "${YELLOW}• Low stock alerts → emails to purchasing@company.com${NC}"
echo -e "${YELLOW}• Critical stock alerts → emails to sales@ and fulfillment@${NC}"
echo
echo -e "${BLUE}${BOLD}Starting log stream...${NC}"
echo -e "${CYAN}===================================================${NC}"
echo

# Follow the notifications service logs
kubectl logs -f deployment/notifications -n default | grep -E "EMAIL NOTIFICATION|Subject:|Dear |Product Details:|Required Actions:|Stock Level:|Alert Time:|Recommended Action:|AUTOMATED SYSTEM ACTIONS|✓|════"