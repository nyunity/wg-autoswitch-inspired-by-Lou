/**
 * Shelly 1 Auto-Switch Script for Shelly 2 Control
 * 
 * This script runs on Shelly 1 and controls a Shelly 2 device via HTTP requests.
 * It uses POST requests to change the relay state and GET requests to verify the changes.
 * 
 * Configuration:
 * - Shelly 2 IP: 192.168.1.82
 * - Uses Shelly RPC API for Gen2 devices
 * 
 * Author: Auto-generated for WireGuard Auto-Switch project
 * Version: 1.0
 */

// Configuration
let CONFIG = {
  shelly2_ip: "192.168.1.82",
  shelly2_port: 80,
  relay_id: 0,  // Relay ID on Shelly 2 (0 or 1)
  timeout: 5000,  // HTTP request timeout in milliseconds
  debug: true,
  auth: {
    enabled: false,  // Set to true if authentication is required
    username: "",    // Set if auth is enabled
    password: ""     // Set if auth is enabled
  }
};

/**
 * Logs messages with timestamp
 * @param {string} level - Log level (INFO, ERROR, DEBUG)
 * @param {string} message - Message to log
 */
function log(level, message) {
  let timestamp = new Date().toISOString();
  print("[" + timestamp + "] [" + level + "] " + message);
}

/**
 * Creates authorization header if authentication is enabled
 * @returns {object} Headers object
 */
function createHeaders() {
  let headers = {
    "Content-Type": "application/json"
  };
  
  if (CONFIG.auth.enabled && CONFIG.auth.username && CONFIG.auth.password) {
    let auth = btoa(CONFIG.auth.username + ":" + CONFIG.auth.password);
    headers["Authorization"] = "Basic " + auth;
  }
  
  return headers;
}

/**
 * Sends a POST request to control Shelly 2 relay
 * @param {boolean} turnOn - true to turn on, false to turn off
 * @param {function} callback - Callback function (optional)
 */
function sendRelayCommand(turnOn, callback) {
  let url = "http://" + CONFIG.shelly2_ip + ":" + CONFIG.shelly2_port + "/rpc";
  
  let payload = {
    id: Date.now(),
    method: "Switch.Set",
    params: {
      id: CONFIG.relay_id,
      on: turnOn
    }
  };
  
  let options = {
    method: "POST",
    headers: createHeaders(),
    body: JSON.stringify(payload),
    timeout: CONFIG.timeout
  };
  
  log("INFO", "Sending " + (turnOn ? "ON" : "OFF") + " command to Shelly 2 relay " + CONFIG.relay_id);
  
  if (CONFIG.debug) {
    log("DEBUG", "POST URL: " + url);
    log("DEBUG", "POST Payload: " + JSON.stringify(payload));
  }
  
  Shelly.call("HTTP.Request", options, function(result, error_code, error_message) {
    if (error_code !== 0) {
      log("ERROR", "HTTP POST request failed: " + error_message + " (code: " + error_code + ")");
      if (callback) callback(false, error_message);
      return;
    }
    
    if (CONFIG.debug) {
      log("DEBUG", "POST Response: " + JSON.stringify(result));
    }
    
    try {
      let response = JSON.parse(result.body);
      if (response.error) {
        log("ERROR", "Shelly 2 RPC error: " + JSON.stringify(response.error));
        if (callback) callback(false, response.error.message);
        return;
      }
      
      log("INFO", "Relay command sent successfully. Response: " + result.body);
      
      // Verify the command was executed by checking status
      setTimeout(function() {
        verifyRelayStatus(turnOn, callback);
      }, 500);  // Wait 500ms before verification
      
    } catch (e) {
      log("ERROR", "Failed to parse POST response: " + e.message);
      if (callback) callback(false, "Invalid JSON response");
    }
  });
}

/**
 * Sends a GET request to verify Shelly 2 relay status
 * @param {boolean} expectedState - Expected relay state
 * @param {function} callback - Callback function (optional)
 */
function verifyRelayStatus(expectedState, callback) {
  let url = "http://" + CONFIG.shelly2_ip + ":" + CONFIG.shelly2_port + "/rpc";
  
  let payload = {
    id: Date.now(),
    method: "Switch.GetStatus",
    params: {
      id: CONFIG.relay_id
    }
  };
  
  let options = {
    method: "POST",
    headers: createHeaders(),
    body: JSON.stringify(payload),
    timeout: CONFIG.timeout
  };
  
  log("INFO", "Verifying Shelly 2 relay " + CONFIG.relay_id + " status");
  
  if (CONFIG.debug) {
    log("DEBUG", "GET URL: " + url);
    log("DEBUG", "GET Payload: " + JSON.stringify(payload));
  }
  
  Shelly.call("HTTP.Request", options, function(result, error_code, error_message) {
    if (error_code !== 0) {
      log("ERROR", "HTTP GET request failed: " + error_message + " (code: " + error_code + ")");
      if (callback) callback(false, error_message);
      return;
    }
    
    if (CONFIG.debug) {
      log("DEBUG", "GET Response: " + JSON.stringify(result));
    }
    
    try {
      let response = JSON.parse(result.body);
      if (response.error) {
        log("ERROR", "Shelly 2 status check RPC error: " + JSON.stringify(response.error));
        if (callback) callback(false, response.error.message);
        return;
      }
      
      let actualState = response.result.output;
      let stateText = actualState ? "ON" : "OFF";
      let expectedText = expectedState ? "ON" : "OFF";
      
      log("INFO", "Relay status verified: " + stateText + " (expected: " + expectedText + ")");
      
      if (actualState === expectedState) {
        log("INFO", "SUCCESS: Relay state matches expected state");
        if (callback) callback(true, "State verified successfully");
      } else {
        log("ERROR", "MISMATCH: Relay state does not match expected state");
        if (callback) callback(false, "State verification failed");
      }
      
    } catch (e) {
      log("ERROR", "Failed to parse GET response: " + e.message);
      if (callback) callback(false, "Invalid JSON response");
    }
  });
}

/**
 * Handles input events from Shelly 1
 * @param {object} eventData - Event data from input
 */
function handleInputEvent(eventData) {
  if (CONFIG.debug) {
    log("DEBUG", "Input event received: " + JSON.stringify(eventData));
  }
  
  // Determine the desired relay state based on input
  let turnOn = false;
  
  if (eventData.component === "input:0") {
    if (eventData.info.event === "single_push" || eventData.info.event === "btn_down") {
      turnOn = true;
      log("INFO", "Input activated - turning Shelly 2 relay ON");
    } else if (eventData.info.event === "btn_up") {
      turnOn = false;
      log("INFO", "Input deactivated - turning Shelly 2 relay OFF");
    } else {
      log("DEBUG", "Ignoring input event: " + eventData.info.event);
      return;
    }
    
    // Send the relay command
    sendRelayCommand(turnOn, function(success, message) {
      if (success) {
        log("INFO", "Relay operation completed successfully");
      } else {
        log("ERROR", "Relay operation failed: " + message);
      }
    });
  }
}

/**
 * Test function to verify HTTP communication
 */
function testCommunication() {
  log("INFO", "Testing communication with Shelly 2...");
  
  // Test status check first
  verifyRelayStatus(false, function(success, message) {
    log("INFO", "Test status check completed. Success: " + success + ", Message: " + message);
  });
}

// Initialize the script
function init() {
  log("INFO", "Shelly 1 Auto-Switch Script initializing...");
  log("INFO", "Target Shelly 2 IP: " + CONFIG.shelly2_ip + ":" + CONFIG.shelly2_port);
  log("INFO", "Target Relay ID: " + CONFIG.relay_id);
  log("INFO", "Authentication: " + (CONFIG.auth.enabled ? "Enabled" : "Disabled"));
  log("INFO", "Debug mode: " + (CONFIG.debug ? "Enabled" : "Disabled"));
  
  // Register event handler for input events
  Shelly.addEventHandler(handleInputEvent);
  
  // Test communication on startup
  setTimeout(function() {
    testCommunication();
  }, 2000);  // Wait 2 seconds after startup
  
  log("INFO", "Script initialization completed");
}

// Start the script
init();