# WireGuard Auto-Switch (Init.d Service)

This script automatically switches between multiple WireGuard servers if the connection to the current server fails. It runs as an **Init.d service**, ensuring automatic startup on boot.

## Features
- **Automatic failover**: If the VPN connection drops, it switches to the next available WireGuard server.
- **Runs as an Init.d service**: Works on older Linux distributions that use SysVinit instead of systemd.
- **Configurable check interval**: Define how often the script should check connectivity.
- **Persistent operation**: The service runs in the background and ensures a stable VPN connection.

## Installation


```bash

wget -qO /etc/init.d/wireguard-switch  https://raw.githubusercontent.com/Lou-Cipher/wg-autoswitch/refs/heads/main/wireguard-switch
wget -qO /usr/bin/wireguard_auto_switch.sh https://raw.githubusercontent.com/Lou-Cipher/wg-autoswitch/refs/heads/main/wireguard_auto_switch.sh
wget -qO /etc/wireguard/wg_auto_switch.conf https://raw.githubusercontent.com/Lou-Cipher/wg-autoswitch/refs/heads/main/wg_auto_switch.conf

chmod +x /usr/bin/wireguard_auto_switch.sh /etc/init.d/wireguard-switch


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
