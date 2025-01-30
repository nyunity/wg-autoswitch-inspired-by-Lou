#!/bin/bash

_wg_conf_dir="/etc/wireguard"

# Read all WireGuard configuration files into an array
readarray -t _wg_confs < <(ls "$_wg_conf_dir"/*.conf | awk -F "/" '{print $NF}' | sed 's/.conf//g')

# Target IP or domain for connectivity check
_test_ip="8.8.8.8"

# Check interval in seconds
_check_int=10

# Get the currently active WireGuard interface
_curr_iface=$(wg show | grep 'interface:' | awk '{print $2}')

# Determine the index of the currently active interface in the _wg_confs array
_curr_index=-1
for i in "${!_wg_confs[@]}"; do
    if [[ "${_wg_confs[$i]}" == "$_curr_iface" ]]; then
        _curr_index=$i
        break
    fi
done

# If no active WireGuard interface is found, start with the first one
if [[ $_curr_index -eq -1 ]]; then
    _curr_index=0
    wg-quick up "${_wg_confs[$_curr_index]}"
fi

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
    # Bring down the current connection
    wg-quick down "${_wg_confs[$_curr_index]}" 2>/dev/null
    # Start new connection
    wg-quick up "$next_config"
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

