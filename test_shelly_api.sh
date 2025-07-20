#!/bin/bash

# Test script to validate Shelly HTTP API calls
# This script simulates the HTTP requests that the Shelly 1 script will make

SHELLY2_IP="192.168.1.82"
SHELLY2_PORT="80"
RELAY_ID="0"

echo "=== Shelly HTTP API Test Script ==="
echo "Target: $SHELLY2_IP:$SHELLY2_PORT"
echo "Relay ID: $RELAY_ID"
echo ""

# Function to test relay ON command
test_relay_on() {
    echo "Testing Relay ON command..."
    PAYLOAD='{
        "id": '$(date +%s)',
        "method": "Switch.Set",
        "params": {
            "id": '$RELAY_ID',
            "on": true
        }
    }'
    
    echo "POST Payload:"
    echo "$PAYLOAD" | jq '.' 2>/dev/null || echo "$PAYLOAD"
    echo ""
    
    RESPONSE=$(curl -s -m 5 \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$PAYLOAD" \
        "http://$SHELLY2_IP:$SHELLY2_PORT/rpc")
    
    echo "Response:"
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    echo ""
}

# Function to test relay OFF command  
test_relay_off() {
    echo "Testing Relay OFF command..."
    PAYLOAD='{
        "id": '$(date +%s)',
        "method": "Switch.Set", 
        "params": {
            "id": '$RELAY_ID',
            "on": false
        }
    }'
    
    echo "POST Payload:"
    echo "$PAYLOAD" | jq '.' 2>/dev/null || echo "$PAYLOAD"
    echo ""
    
    RESPONSE=$(curl -s -m 5 \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$PAYLOAD" \
        "http://$SHELLY2_IP:$SHELLY2_PORT/rpc")
    
    echo "Response:"
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    echo ""
}

# Function to test status check
test_status_check() {
    echo "Testing Status Check..."
    PAYLOAD='{
        "id": '$(date +%s)',
        "method": "Switch.GetStatus",
        "params": {
            "id": '$RELAY_ID'
        }
    }'
    
    echo "POST Payload:"
    echo "$PAYLOAD" | jq '.' 2>/dev/null || echo "$PAYLOAD"
    echo ""
    
    RESPONSE=$(curl -s -m 5 \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$PAYLOAD" \
        "http://$SHELLY2_IP:$SHELLY2_PORT/rpc")
    
    echo "Response:"
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    echo ""
}

# Function to test network connectivity
test_connectivity() {
    echo "Testing network connectivity to $SHELLY2_IP..."
    
    if ping -c 1 -W 3 "$SHELLY2_IP" >/dev/null 2>&1; then
        echo "✓ Ping successful"
    else
        echo "✗ Ping failed"
        return 1
    fi
    
    if curl -s -m 3 "http://$SHELLY2_IP:$SHELLY2_PORT" >/dev/null 2>&1; then
        echo "✓ HTTP connection successful"
    else
        echo "✗ HTTP connection failed"
        return 1
    fi
    
    echo ""
    return 0
}

# Main test sequence
echo "1. Testing network connectivity..."
if ! test_connectivity; then
    echo "Network connectivity test failed. Please check:"
    echo "- Shelly 2 device is powered on"
    echo "- IP address $SHELLY2_IP is correct"
    echo "- Network connectivity between devices"
    exit 1
fi

echo "2. Testing status check (baseline)..."
test_status_check

echo "3. Testing relay ON command..."
test_relay_on

echo "4. Waiting 2 seconds..."
sleep 2

echo "5. Testing status check (should be ON)..."
test_status_check

echo "6. Testing relay OFF command..."
test_relay_off

echo "7. Waiting 2 seconds..."
sleep 2

echo "8. Testing status check (should be OFF)..."
test_status_check

echo "=== Test completed ==="
echo ""
echo "If all tests show proper JSON responses without errors,"
echo "the Shelly 1 script should work correctly."
echo ""
echo "Expected successful response format:"
echo '{"id": 123456789, "src": "shellypro2-aabbccddeeff", "result": {"was_on": false}}'