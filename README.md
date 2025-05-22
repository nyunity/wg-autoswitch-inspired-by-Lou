# WireGuard Auto-Switch (Systemd Service)

This script automatically switches between multiple WireGuard servers if the connection to the current server fails. It runs as an **Init.d service**, ensuring automatic startup on boot.

## Features
- **Automatic failover**: If the VPN connection drops, it switches to the next available WireGuard server.
- **Runs as an systemd service**: less resources and better log.
- **Configurable check interval**: Define how often the script should check connectivity.
- **Persistent operation**: The service runs in the background and ensures a stable VPN connection.
- **Boot Checks**: Checks if the hostname of wgx.conf is available, if not, it tries the next one

## Bonus
I have another script that checks if my server is connected to Mullvad, if not, I receive an email and a push notification via ntfy. See wg-mullvad-check.sh. After using this, insert crontab -e: */5 * * * * /usr/local/bin/wg-check-all.sh

## Installation

```bash

wget -qO /etc/wireguard/wg_auto_switch.conf https://raw.githubusercontent.com/Lou-Cipher/wg-autoswitch/refs/heads/main/wg_auto_switch.conf
/etc/systemd/system/ => wireguard-autoswitch.service
/usr/bin/ => wireguard_auto_switch.sh => chmod +x
/usr/local/bin/ => wg-check-all.sh => chmod +x

systemctl daemon-reload
systemctl enable --now wireguard-autoswitch.service

```

Configuration file for the script: 
```bash
/etc/wireguard/wg_auto_switch.conf
```
