#!/bin/bash

# Script to load initial review data via the Reviews Service API
# Usage: ./load-initial-data.sh [base_url]

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common/setup/common-utils.sh"

# Use provided base URL or default to localhost
BASE_URL="${1:-http://localhost/reviews-service}"

echo "Loading initial review data to: $BASE_URL"
echo "========================================"

# Wait for service to be ready
if ! wait_for_service "$BASE_URL"; then
  print_error "Service is not ready. Exiting."
  exit 1
fi

echo ""
# Initial review data - 40 reviews with natural distribution and explicit IDs
# Customer IDs 1-10 from customer service
# Product IDs 1001-1010 from product service
# Review IDs 4001-4040
declare -a reviews=(
  # Product 1001 (Smartphone XS) - 8 reviews (most popular)
  '{"reviewId": 4001, "productId": 1001, "customerId": 1, "rating": 5, "reviewText": "Excellent smartphone! The camera quality is outstanding and the battery life is impressive."}'
  '{"reviewId": 4002, "productId": 1001, "customerId": 4, "rating": 4, "reviewText": "Great phone overall, but a bit pricey. Performance is smooth and design is sleek."}'
  '{"reviewId": 4003, "productId": 1001, "customerId": 8, "rating": 5, "reviewText": "Best phone I have ever owned. Fast, reliable, and the display is gorgeous!"}'
  '{"reviewId": 4004, "productId": 1001, "customerId": 2, "rating": 4, "reviewText": "Good value for money. The 5G connectivity is super fast."}'
  '{"reviewId": 4005, "productId": 1001, "customerId": 5, "rating": 5, "reviewText": "Amazing camera features! Night mode is incredible."}'
  '{"reviewId": 4006, "productId": 1001, "customerId": 9, "rating": 3, "reviewText": "Good phone but battery drains quickly with heavy use."}'
  '{"reviewId": 4007, "productId": 1001, "customerId": 3, "rating": 5, "reviewText": ""}'
  '{"reviewId": 4008, "productId": 1001, "customerId": 6, "rating": 4, "reviewText": "Solid performance, great for multitasking."}'
  
  # Product 1002 (Wireless Headphones Pro) - 6 reviews (popular accessory)
  '{"reviewId": 4009, "productId": 1002, "customerId": 2, "rating": 4, "reviewText": "Good sound quality and comfortable to wear. Noise cancellation works well."}'
  '{"reviewId": 4010, "productId": 1002, "customerId": 3, "rating": 3, "reviewText": "Decent headphones but the battery life could be better."}'
  '{"reviewId": 4011, "productId": 1002, "customerId": 7, "rating": 5, "reviewText": ""}'
  '{"reviewId": 4012, "productId": 1002, "customerId": 1, "rating": 4, "reviewText": "Great for calls and music. Bluetooth connection is stable."}'
  '{"reviewId": 4013, "productId": 1002, "customerId": 8, "rating": 5, "reviewText": "Best noise cancellation I have experienced. Worth every penny!"}'
  '{"reviewId": 4014, "productId": 1002, "customerId": 10, "rating": 4, "reviewText": "Comfortable even after long use. Sound quality exceeds expectations."}'
  
  # Product 1003 (Smart Watch Ultra) - 5 reviews (fitness enthusiasts)
  '{"reviewId": 4015, "productId": 1003, "customerId": 1, "rating": 4, "reviewText": "Great fitness tracker with accurate heart rate monitoring."}'
  '{"reviewId": 4016, "productId": 1003, "customerId": 6, "rating": 5, "reviewText": "Love this watch! Tracks everything I need and looks stylish too."}'
  '{"reviewId": 4017, "productId": 1003, "customerId": 3, "rating": 4, "reviewText": "Battery lasts 2 days with heavy use. GPS is accurate."}'
  '{"reviewId": 4018, "productId": 1003, "customerId": 8, "rating": 5, "reviewText": ""}'
  '{"reviewId": 4019, "productId": 1003, "customerId": 2, "rating": 5, "reviewText": "Best smartwatch for fitness enthusiasts. Waterproof works great!"}'
  
  # Product 1004 (Tablet Pro 12.9") - 4 reviews (premium product, fewer buyers)
  '{"reviewId": 4020, "productId": 1004, "customerId": 4, "rating": 5, "reviewText": "Amazing tablet for creative work. The stylus is very responsive."}'
  '{"reviewId": 4021, "productId": 1004, "customerId": 10, "rating": 4, "reviewText": ""}'
  '{"reviewId": 4022, "productId": 1004, "customerId": 1, "rating": 5, "reviewText": "Perfect for digital art. Screen quality is outstanding."}'
  '{"reviewId": 4023, "productId": 1004, "customerId": 7, "rating": 5, "reviewText": "Replaced my laptop for most tasks. Very powerful and portable."}'
  
  # Product 1005 (Bluetooth Speaker Max) - 3 reviews (moderate popularity)
  '{"reviewId": 4024, "productId": 1005, "customerId": 5, "rating": 3, "reviewText": "Good speaker but not as loud as advertised."}'
  '{"reviewId": 4025, "productId": 1005, "customerId": 7, "rating": 4, "reviewText": "Waterproof feature works great! Perfect for pool parties."}'
  '{"reviewId": 4026, "productId": 1005, "customerId": 9, "rating": 4, "reviewText": ""}'
  
  # Product 1006 (Power Bank 20000mAh) - 2 reviews (least popular)
  '{"reviewId": 4027, "productId": 1006, "customerId": 2, "rating": 2, "reviewText": "Charges slowly and gets warm. Expected better quality."}'
  '{"reviewId": 4028, "productId": 1006, "customerId": 6, "rating": 3, "reviewText": "Works as expected but nothing special. Decent backup option."}'
  
  # Product 1007 (Gaming Laptop RTX) - 5 reviews (expensive but gamers love it)
  '{"reviewId": 4029, "productId": 1007, "customerId": 1, "rating": 5, "reviewText": "Incredible gaming performance! Runs all modern games at max settings."}'
  '{"reviewId": 4030, "productId": 1007, "customerId": 4, "rating": 5, "reviewText": "Worth every penny. Build quality is excellent."}'
  '{"reviewId": 4031, "productId": 1007, "customerId": 10, "rating": 4, "reviewText": ""}'
  '{"reviewId": 4032, "productId": 1007, "customerId": 7, "rating": 5, "reviewText": "Beast of a machine! RTX 4080 handles everything I throw at it."}'
  '{"reviewId": 4033, "productId": 1007, "customerId": 3, "rating": 5, "reviewText": "Perfect for both gaming and content creation. No regrets!"}'
  
  # Product 1008 (Mechanical Keyboard RGB) - 3 reviews (niche product)
  '{"reviewId": 4034, "productId": 1008, "customerId": 6, "rating": 4, "reviewText": "Nice mechanical feel and RGB lighting. Cherry switches are great."}'
  '{"reviewId": 4035, "productId": 1008, "customerId": 7, "rating": 5, "reviewText": "Best keyboard for the price! Typing experience is fantastic."}'
  '{"reviewId": 4036, "productId": 1008, "customerId": 9, "rating": 3, "reviewText": ""}'
  
  # Product 1009 (4K Webcam Pro) - 4 reviews (popular for remote work)
  '{"reviewId": 4037, "productId": 1009, "customerId": 2, "rating": 5, "reviewText": "Crystal clear video quality. Autofocus works like magic."}'
  '{"reviewId": 4038, "productId": 1009, "customerId": 4, "rating": 4, "reviewText": "Great webcam for remote work. Much better than laptop camera."}'
  '{"reviewId": 4039, "productId": 1009, "customerId": 8, "rating": 5, "reviewText": ""}'
  '{"reviewId": 4040, "productId": 1009, "customerId": 1, "rating": 5, "reviewText": "AI-powered features are impressive. Worth the investment."}'
  
  # Product 1010 (USB-C Hub 10-in-1) - 2 reviews (practical accessory)
  '{"reviewId": 4041, "productId": 1010, "customerId": 5, "rating": 4, "reviewText": "All ports work as expected. Good build quality."}'
  '{"reviewId": 4042, "productId": 1010, "customerId": 3, "rating": 5, "reviewText": "Essential for my MacBook. All ports work perfectly, no issues."}'
)

# Track results
success_count=0
fail_count=0

# Create each review
for review in "${reviews[@]}"; do
  review_id=$(echo "$review" | grep -o '"reviewId": [0-9]*' | cut -d' ' -f2)
  product_id=$(echo "$review" | grep -o '"productId": [0-9]*' | cut -d' ' -f2)
  customer_id=$(echo "$review" | grep -o '"customerId": [0-9]*' | cut -d' ' -f2)
  rating=$(echo "$review" | grep -o '"rating": [0-9]' | cut -d' ' -f2)
  
  echo -n "Creating review ID $review_id for Product $product_id by Customer $customer_id (Rating: $rating)... "
  
  response=$(make_request_with_retry "POST" "$BASE_URL/reviews" "$review")
  
  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | sed '$d')
  
  if [ "$http_code" = "201" ]; then
    print_success "SUCCESS"
    ((success_count++))
  else
    print_error "FAILED (HTTP $http_code)"
    echo "  Error: $body"
    ((fail_count++))
  fi
done

echo ""
echo "========================================"
echo "Summary: $success_count succeeded, $fail_count failed"

# Print distribution summary
echo ""
echo "Review Distribution by Product:"
echo "------------------------------"
for product_id in 1001 1002 1003 1004 1005 1006 1007 1008 1009 1010; do
  count=$(echo "${reviews[@]}" | grep -o "\"productId\": $product_id" | wc -l | tr -d ' ')
  echo "Product $product_id: $count reviews"
done

echo ""
echo "Review IDs: 4001-4042"

if [ $fail_count -eq 0 ]; then
  print_success "All reviews loaded successfully!"
  exit 0
else
  print_error "Some reviews failed to load"
  exit 1
fi