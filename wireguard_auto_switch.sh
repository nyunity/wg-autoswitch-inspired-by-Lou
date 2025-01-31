#!/bin/bash

# Load external configuration file
source /etc/wireguard/wg_auto_switch.conf

# Function to log messages and check log file size
echo_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$_log_file"
    manage_log_size
}

# Function to manage log file size
manage_log_size() {
    if [[ -f "$_log_file" && $(stat -c%s "$_log_file") -ge $_max_log_size ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Log file exceeded 5MB, truncating to 2MB..." | tee -a "$_log_file"
        truncate -s $_truncate_size "$_log_file"
    fi
}

# Read WireGuard configuration files excluding the config file itself
readarray -t _wg_confs < <(ls "$_wg_conf_dir"/*.conf 2>/dev/null | grep -v "wg_auto_switch.conf" | awk -F "/" '{print $NF}' | sed 's/.conf//g')

if [[ ${#_wg_confs[@]} -eq 0 ]]; then
    echo_log "No WireGuard configurations found! Exiting script."
    exit 1
fi

# Get the currently active WireGuard interface
_curr_iface=$(wg show | grep 'interface:' | awk '{print $2}')

# Determine the index of the currently active interface
_curr_index=-1
for i in "${!_wg_confs[@]}"; do
    if [[ "${_wg_confs[$i]}" == "$_curr_iface" ]]; then
        _curr_index=$i
        break
    fi
done

# If no active WireGuard interface is found, start with the first one
if [[ $_curr_index -eq -1 ]]; then
    echo_log "No active WireGuard connection found. Starting first available configuration..."
    _curr_index=0
    if ! wg-quick up "${_wg_confs[$_curr_index]}" 2>>"$_log_file"; then
        echo_log "Error starting ${_wg_confs[$_curr_index]}"
        exit 1
    fi
fi

# Function to check connection
check_connection() {
    ping -c 2 -W 3 "$_test_ip" &>/dev/null
    return $?
}

# Function to switch the WireGuard server
switch_server() {
    local next_index=$(( (_curr_index + 1) % ${#_wg_confs[@]} ))
    local next_config="${_wg_confs[$next_index]}"
    echo_log "Connection failed! Switching to server: $next_config"
    
    # Bring down the current connection
    wg-quick down "${_wg_confs[$_curr_index]}" 2>>"$_log_file" || echo_log "Error stopping ${_wg_confs[$_curr_index]}"
    
    # Start new connection
    if ! wg-quick up "$next_config" 2>>"$_log_file"; then
        echo_log "Error starting $next_config"
        exit 1
    fi
    
    # Pause after switching
    echo_log "Pausing for 30 seconds after switching..."
    sleep 30
    
    # Update index
    _curr_index=$next_index
}

# Main loop
while true; do
    if ! check_connection; then
        switch_server
    fi
    sleep "$_check_int"
done

