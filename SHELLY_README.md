# Shelly Auto-Switch Script

This project contains a JavaScript script for Shelly 1 devices to control Shelly 2 devices via HTTP requests using the Shelly RPC API.

## Overview

The `shelly1_autoswitch.js` script enables a Shelly 1 device to:
- Send POST requests to control a Shelly 2 relay (on/off)
- Send GET requests to verify the relay status
- Provide comprehensive logging for debugging
- Handle authentication if required
- Respond to input events (button presses, switches)

## Configuration

### Shelly 2 Settings
- **IP Address**: 192.168.1.82 (configured in script)
- **Port**: 80 (default HTTP port)
- **Relay ID**: 0 (can be changed to 1 for second relay)

### Authentication
If your Shelly 2 device has authentication enabled:
1. Set `CONFIG.auth.enabled = true`
2. Provide username and password in the script
3. The script will automatically include Basic Auth headers

## Installation

### Step 1: Prepare the Script
1. Download or copy the `shelly1_autoswitch.js` file
2. Modify the configuration section if needed:
   ```javascript
   let CONFIG = {
     shelly2_ip: "192.168.1.82",  // Change if different IP
     relay_id: 0,                 // Change to 1 for second relay
     debug: true,                 // Set to false to reduce logging
     auth: {
       enabled: false,            // Set to true if auth required
       username: "",              // Your Shelly 2 username
       password: ""               // Your Shelly 2 password
     }
   };
   ```

### Step 2: Upload to Shelly 1
1. Open your Shelly 1 web interface (http://[SHELLY1_IP])
2. Navigate to **Settings** → **Actions**
3. Create a new script or edit existing one
4. Copy and paste the entire content of `shelly1_autoswitch.js`
5. Save the script

### Step 3: Configure Input Events
1. In Shelly 1 settings, go to **Settings** → **Actions**
2. Make sure the script is enabled and running
3. The script will automatically handle input events from input:0

## API Endpoints Used

### POST Request - Control Relay
- **URL**: `http://192.168.1.82/rpc`
- **Method**: POST
- **Payload**:
  ```json
  {
    "id": 1234567890,
    "method": "Switch.Set",
    "params": {
      "id": 0,
      "on": true
    }
  }
  ```

### GET Request - Check Status  
- **URL**: `http://192.168.1.82/rpc`
- **Method**: POST (RPC uses POST for all calls)
- **Payload**:
  ```json
  {
    "id": 1234567890,
    "method": "Switch.GetStatus",
    "params": {
      "id": 0
    }
  }
  ```

## Script Behavior

### Input Events
- **Button Press/Switch On**: Sends ON command to Shelly 2
- **Button Release/Switch Off**: Sends OFF command to Shelly 2
- **Status Verification**: After each command, verifies the actual state

### Logging
The script provides detailed logging including:
- Timestamp for each action
- Success/failure of HTTP requests
- Request and response details (when debug mode is enabled)
- Status verification results

### Error Handling
- HTTP request timeouts (5 second default)
- JSON parsing errors
- RPC error responses
- Network connectivity issues
- Authentication failures

## Troubleshooting

### Common Issues

1. **Shelly 2 Not Responding**
   - Check if IP address 192.168.1.82 is correct
   - Verify network connectivity between devices
   - Ensure Shelly 2 is powered on and connected to WiFi

2. **Authentication Errors**
   - Enable authentication in CONFIG if Shelly 2 requires it
   - Verify username and password are correct
   - Check if Shelly 2 authentication is properly configured

3. **RPC Errors**
   - Ensure Shelly 2 firmware supports RPC API (Gen2 devices)
   - Check relay ID (0 or 1) matches actual relay on Shelly 2
   - Verify Shelly 2 is not in factory reset mode

4. **Script Not Running**
   - Check Shelly 1 script console for errors
   - Ensure script is enabled in Shelly 1 settings
   - Verify JavaScript syntax is correct

### Debug Mode
Enable debug mode by setting `CONFIG.debug = true` to see:
- Full HTTP request and response details
- Input event information
- Detailed timing information

### Log Examples

Successful operation:
```
[2024-01-15T10:30:15.123Z] [INFO] Input activated - turning Shelly 2 relay ON
[2024-01-15T10:30:15.234Z] [INFO] Sending ON command to Shelly 2 relay 0
[2024-01-15T10:30:15.345Z] [INFO] Relay command sent successfully
[2024-01-15T10:30:15.856Z] [INFO] Verifying Shelly 2 relay 0 status
[2024-01-15T10:30:15.967Z] [INFO] Relay status verified: ON (expected: ON)
[2024-01-15T10:30:15.968Z] [INFO] SUCCESS: Relay state matches expected state
```

Error example:
```
[2024-01-15T10:30:15.123Z] [ERROR] HTTP POST request failed: Connection timeout (code: -1)
[2024-01-15T10:30:15.124Z] [ERROR] Relay operation failed: Connection timeout
```

## Firmware Compatibility

- **Shelly 1**: Any firmware version supporting JavaScript actions
- **Shelly 2**: Gen2 firmware with RPC API support (firmware 0.9.0+)

## Security Considerations

- Use authentication on Shelly 2 if the device is accessible from outside your local network
- Consider using HTTPS if your Shelly 2 supports it
- Regularly update firmware on both devices
- Monitor logs for suspicious activity

## Support

For issues related to:
- Shelly device configuration: Check Shelly official documentation
- Script modifications: Refer to Shelly scripting documentation
- Network connectivity: Check your router and network settings