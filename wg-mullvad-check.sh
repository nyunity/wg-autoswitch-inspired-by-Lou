#!/bin/bash

# === Konfiguration ===
EMAIL_TO="email@an.de"
NTFY_TOPIC="deinTopicbeiNTFY"
NTFY_URL="https://ntfy.sh/$NTFY_TOPIC"

# === Aktive WireGuard-Interfaces prüfen ===
active_wg=""
for n in {0..16}; do
    IF="wg$n"
    if ip link show "$IF" 2>/dev/null | grep -q "state UP"; then
        active_wg="$active_wg $IF"
    fi
done

# === Mullvad-Check Funktion ===
check_mullvad() {
    curl -sS https://am.i.mullvad.net/connected
}

MULLVAD_STATUS=$(check_mullvad)

if ! echo "$MULLVAD_STATUS" | grep -qi "You are connected to Mullvad"; then
    # Vor Alarm: Neustart WireGuard versuchen
    systemctl restart wireguard-autoswitch

    # Kurze Pause (z.B. 10 Sekunden), damit die Verbindung Zeit hat
    sleep 10

    # Nochmals prüfen
    MULLVAD_STATUS=$(check_mullvad)
    if ! echo "$MULLVAD_STATUS" | grep -qi "You are connected to Mullvad"; then
        MSG="Achtung! Du bist laut Mullvad NICHT geschützt.
Aktive WireGuard-Interfaces:${active_wg:- keine}
Zeitpunkt: $(date)
Antwort von Mullvad: $MULLVAD_STATUS
Bitte prüfe deine VPN-Verbindung!"

        # ntfy Push-Nachricht
        curl -H "Title: Alarm vom AdGuard Server" -d "$MSG" "$NTFY_URL"

        # E-Mail senden
        echo -e "$MSG" -s "Alarm vom AdGuard Server" | msmtp  "$EMAIL_TO"
        exit 1
    fi
fi

# Alles OK
exit 0
