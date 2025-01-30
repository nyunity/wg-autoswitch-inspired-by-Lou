# WireGuard Auto-Switch (Init.d Service)

This script automatically switches between multiple WireGuard servers if the connection to the current server fails. It runs as an **Init.d service**, ensuring automatic startup on boot.

## Features
- **Automatic failover**: If the VPN connection drops, it switches to the next available WireGuard server.
- **Runs as an Init.d service**: Works on older Linux distributions that use SysVinit instead of systemd.
- **Configurable check interval**: Define how often the script should check connectivity.
- **Persistent operation**: The service runs in the background and ensures a stable VPN connection.

## Installation


```bash
cat > /usr/local/bin/wireguard_auto_switch.sh << __EOF__ 
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

__EOF__

cat > /etc/init.d/wireguard-switch << __EOF__
#!/bin/bash
### BEGIN INIT INFO
# Provides:          wireguard-switch
# Required-Start:    $network $remote_fs
# Required-Stop:     $network $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: LouCipher's Automatic WireGuard Server Switcher
# Description:       Monitors connectivity and switches the WireGuard server if the connection fails.
### END INIT INFO

SCRIPT="/usr/local/bin/wireguard_auto_switch.sh"
PIDFILE="/var/run/wireguard-switch.pid"

start() {
    echo "Starting WireGuard Auto-Switch..."
    nohup $SCRIPT > /var/log/wireguard-switch.log 2>&1 & echo $! > $PIDFILE
    echo "Started with PID $(cat $PIDFILE)"
}

stop() {
    echo "Stopping WireGuard Auto-Switch..."
    if [ -f $PIDFILE ]; then
        kill $(cat $PIDFILE)
        rm -f $PIDFILE
        echo "Stopped."
    else
        echo "Service is not running."
    fi
}

restart() {
    stop
    sleep 2
    start
}

status() {
    if [ -f $PIDFILE ]; then
        echo "WireGuard Auto-Switch is running with PID $(cat $PIDFILE)"
    else
        echo "WireGuard Auto-Switch is not running."
    fi
}

case "$1" in
    start) start ;;
    stop) stop ;;
    restart) restart ;;
    status) status ;;
    *) echo "Usage: $0 {start|stop|restart|status}" ;;
esac

exit 0
__EOF__



chmod +x /usr/local/bin/wireguard_auto_switch.sh /etc/init.d/wireguard-switch


update-rc.d wireguard-switch defaults
```


To start the service:
```bash
/etc/init.d/wireguard-switch start
```

To stop the service:
```bash
/etc/init.d/wireguard-switch stop
```

To restart the service:
```bash
/etc/init.d/wireguard-switch restart
```

To check the status:
```bash
/etc/init.d/wireguard-switch status
```

To disable the service:
```bash
update-rc.d -f wireguard-switch remove
```
