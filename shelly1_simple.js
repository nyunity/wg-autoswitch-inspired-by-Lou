/**
 * Shelly 1 Auto-Switch Script (Minimal Version)
 * 
 * Simplified version for easier deployment and testing.
 * Controls Shelly 2 at 192.168.1.82 via HTTP RPC calls.
 */

// === CONFIGURATION ===
let SHELLY2_IP = "192.168.1.82";
let RELAY_ID = 0;
let DEBUG = true;

// === LOGGING ===
function log(message) {
  print("[" + new Date().toISOString() + "] " + message);
}

// === HTTP REQUESTS ===
function sendCommand(turnOn, callback) {
  let url = "http://" + SHELLY2_IP + "/rpc";
  let payload = {
    id: Date.now(),
    method: "Switch.Set",
    params: { id: RELAY_ID, on: turnOn }
  };
  
  log("Sending " + (turnOn ? "ON" : "OFF") + " command to Shelly 2");
  
  if (DEBUG) log("Request: " + JSON.stringify(payload));
  
  Shelly.call("HTTP.Request", {
    method: "POST",
    url: url,
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify(payload),
    timeout: 5
  }, function(result, error_code, error_message) {
    if (error_code !== 0) {
      log("ERROR: " + error_message);
      if (callback) callback(false);
      return;
    }
    
    if (DEBUG) log("Response: " + result.body);
    
    try {
      let response = JSON.parse(result.body);
      if (response.error) {
        log("RPC Error: " + response.error.message);
        if (callback) callback(false);
      } else {
        log("Command successful");
        // Verify status after 500ms
        setTimeout(function() { checkStatus(turnOn, callback); }, 500);
      }
    } catch (e) {
      log("Parse error: " + e.message);
      if (callback) callback(false);
    }
  });
}

function checkStatus(expectedState, callback) {
  let url = "http://" + SHELLY2_IP + "/rpc";
  let payload = {
    id: Date.now(),
    method: "Switch.GetStatus",
    params: { id: RELAY_ID }
  };
  
  log("Checking relay status...");
  
  Shelly.call("HTTP.Request", {
    method: "POST",
    url: url,
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify(payload),
    timeout: 5
  }, function(result, error_code, error_message) {
    if (error_code !== 0) {
      log("Status check failed: " + error_message);
      if (callback) callback(false);
      return;
    }
    
    try {
      let response = JSON.parse(result.body);
      if (response.error) {
        log("Status RPC Error: " + response.error.message);
        if (callback) callback(false);
      } else {
        let actualState = response.result.output;
        let match = actualState === expectedState;
        log("Status: " + (actualState ? "ON" : "OFF") + 
            " (expected: " + (expectedState ? "ON" : "OFF") + 
            ") - " + (match ? "SUCCESS" : "MISMATCH"));
        if (callback) callback(match);
      }
    } catch (e) {
      log("Status parse error: " + e.message);
      if (callback) callback(false);
    }
  });
}

// === EVENT HANDLER ===
function handleEvent(eventData) {
  if (DEBUG) log("Event: " + JSON.stringify(eventData));
  
  if (eventData.component === "input:0") {
    let turnOn = false;
    
    if (eventData.info.event === "single_push" || 
        eventData.info.event === "btn_down") {
      turnOn = true;
      log("Input ON - switching relay ON");
    } else if (eventData.info.event === "btn_up") {
      turnOn = false;
      log("Input OFF - switching relay OFF");
    } else {
      return; // Ignore other events
    }
    
    sendCommand(turnOn);
  }
}

// === INITIALIZATION ===
log("Shelly Auto-Switch starting...");
log("Target: " + SHELLY2_IP + ", Relay: " + RELAY_ID);

// Register event handler
Shelly.addEventHandler(handleEvent);

// Test communication
setTimeout(function() {
  log("Testing communication...");
  checkStatus(false);
}, 2000);

log("Script initialized successfully");