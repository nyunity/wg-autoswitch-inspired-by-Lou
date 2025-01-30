#!/bin/bash

_wg_conf_dir="/etc/wireguard"

# List of WireGuard configuration files
_wg_confs=$(ls $_wg_conf_dir/*.conf |awk -F "$_wg_conf_dir/" '{print $2}')

# Target IP or domain for connectivity check
_test_ip="8.8.8.8"

# Check interval in seconds
_check_int=10

# Current index in the server list
_curr_index=0

# Function to check connection
check_connection() {
    ping -c 2 -W 3 "$_test_ip" &> /dev/null
    return $?
}

# Function to switch the WireGuard server
switch_server() {
    local next_index=$(( (_curr_index + 1) % ${#_wg_confs[@]} ))
    local next_config="${_wg_confs[$next_index]}"

    echo "Connection failed! Switching to server: $next_config"

    # Bring down current connection
    wg-quick down "${_wg_confs[$_curr_index]}" 2>/dev/null

    # Start new connection
    wg-quick up "${_wg_conf_dir}/$next_config"

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

