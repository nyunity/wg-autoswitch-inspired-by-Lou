#!/bin/bash
#
# WireGuard Auto-Switch & Failover Script
# ---------------------------------------
# Dieses Script prüft regelmäßig die VPN-Verbindung (WireGuard) und schaltet bei Ausfall
# automatisch auf die nächste verfügbare Konfiguration um.
#
# Voraussetzungen:
# - bash
# - wg-quick / WireGuard installiert
# - Konfigurationsdatei (s.u.)
#
# Externe Konfiguration (z.B. /etc/wireguard/wg_auto_switch.conf):
# ---------------------------------------------------------------
# _wg_conf_dir="/etc/wireguard"    # Verzeichnis mit wgX.conf Dateien
# _log_file="/var/log/wireguard_failover.log"
# _test_ip="8.8.8.8"               # IP zur Verbindungsprüfung (z.B. Google DNS)
# _check_int=10                    # Prüfintervall in Sekunden
# _switch_pause=10                 # Pause nach Umschalten in Sekunden
# _max_log_size=5242880            # Max. Logfilegröße (Bsp.: 5MB)
# _truncate_size=2097152           # Nach Überschreiten auf diese Größe kürzen (Bsp.: 2MB)
#
# ----------------------------------------------------------------

# --- Konfiguration laden ---
_config_file="/etc/wireguard/wg_auto_switch.conf"
if [[ ! -f "$_config_file" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Konfigurationsdatei $_config_file nicht gefunden! Abbruch." | tee -a "/var/log/wireguard_failover.log"
    exit 1
fi
source "$_config_file"

# --- Logging-Funktion mit Logfile-Management ---
echo_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$_log_file"
    manage_log_size
}
manage_log_size() {
    if [[ -f "$_log_file" && $(stat -c%s "$_log_file") -ge $_max_log_size ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Logfile überschreitet $_max_log_size Bytes, kürze auf $_truncate_size..." | tee -a "$_log_file"
        truncate -s $_truncate_size "$_log_file"
    fi
}

# --- WireGuard-Konfigurationen finden ---
readarray -t _wg_confs < <(ls "$_wg_conf_dir"/*.conf 2>/dev/null | grep -v "wg_auto_switch.conf" | awk -F "/" '{print $NF}' | sed 's/.conf//g')
if [[ ${#_wg_confs[@]} -eq 0 ]]; then
    echo_log "Keine WireGuard-Konfigurationen gefunden! Script wird beendet."
    exit 1
fi

# --- DNS-Warteschleife: Warte bis alle Hostnamen der Endpunkte auflösbar sind (max. 5min pro Host) ---
declare -a HOSTS=()
for conf in "$_wg_conf_dir"/*.conf; do
    EP=$(grep -i "^Endpoint" "$conf" | awk '{print $3}' | cut -d: -f1)
    # Nur Hostnamen (keine IPs) berücksichtigen
    if [[ -n "$EP" && ! "$EP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        HOSTS+=("$EP")
    fi
done
for host in "${HOSTS[@]}"; do
    waited=0
    max_wait=300   # 5min pro Host
    while ! getent hosts "$host" >/dev/null; do
        echo_log "Warte auf DNS-Auflösung für $host..."
        sleep 5
        waited=$((waited+5))
        if [ $waited -ge $max_wait ]; then
            echo_log "Timeout beim Warten auf DNS für $host. Fahre fort."
            break
        fi
    done
done

# --- Aktives Interface ermitteln ---
_curr_iface=$(wg show | grep 'interface:' | awk '{print $2}')
_curr_index=-1
for i in "${!_wg_confs[@]}"; do
    if [[ "${_wg_confs[$i]}" == "$_curr_iface" ]]; then
        _curr_index=$i
        break
    fi
done

# --- Start: Falls kein Interface aktiv, erstes starten ---
if [[ $_curr_index -eq -1 ]]; then
    echo_log "Kein aktives WireGuard-Interface gefunden. Starte erste Konfiguration: ${_wg_confs[0]}"
    _curr_index=0
    if ! wg-quick up "${_wg_confs[$_curr_index]}" 2>>"$_log_file"; then
        echo_log "Fehler beim Start von ${_wg_confs[$_curr_index]}"
        exit 1
    fi
fi

# --- Verbindung prüfen ---
check_connection() {
    ping -c 2 -W 3 "$_test_ip" &>/dev/null
    return $?
}

# --- Umschalten auf nächste Konfiguration ---
switch_server() {
    local next_index=$(( (_curr_index + 1) % ${#_wg_confs[@]} ))
    local next_config="${_wg_confs[$next_index]}"
    echo_log "Verbindung fehlgeschlagen! Wechsele zu: $next_config"
    wg-quick down "${_wg_confs[$_curr_index]}" 2>>"$_log_file" || echo_log "Fehler beim Stoppen von ${_wg_confs[$_curr_index]}"
    if ! wg-quick up "$next_config" 2>>"$_log_file"; then
        echo_log "Fehler beim Start von $next_config"
        exit 1
    fi
    echo_log "Pause $_switch_pause Sekunden nach Wechsel..."
    sleep "$_switch_pause"
    _curr_index=$next_index
}

# --- Hauptloop ---
while true; do
    if ! check_connection; then
        switch_server
    fi
    sleep "$_check_int"
done
