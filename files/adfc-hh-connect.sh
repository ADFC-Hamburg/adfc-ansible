#!/bin/bash
# Aufbau einer VPN-Verbindung zum ADFC-HH UCS-MASTER


# Uptime & Hostname
UT=$(uptime | cut -d ' ' -f 4)
HOST=$(hostname)


# Alte Fehlermeldungen löschen
find /$HOST* -mtime 1 -exec rm {} \;


# Herstellen der VPN-Verbindung
vpnc adfc-hh.conf
sleep 5


# Test und Fehlerbehandlung, falls VPN-Tunnel nicht aufgebaut wurde
ping -c 3 192.168.123.32 #2>&1> /dev/null
if [ $? -ne 0 ]; then 
# Fehler bei Verbindungsaufbau aufgetreten
    vpnc-disconnect
    sleep 5
    killall vpnc
    sleep 5
# Kein weiter Verbindungsversuch bei Mehrfachfehler
    if [ -f "/$HOST-REBOOT" ]; then
	touch /$HOST-VERBINDUNGSFEHLER
        exit 1
    fi

# erneuter Versuch ...
    vpnc adfc-hh.conf
    sleep 5
    ping -c 3 192.168.3.32 2>&1> /dev/null
# Reboot wenn nicht erfolgreich
    if [ $? -ne 0 ]; then 
        if [ $UT -lt 5 ]; then
           touch /$HOST-REBOOT
           reboot
        fi
    fi
fi
# Verbindung wurde erfolgreich hergestellt


# Daten für Token ermitteln
IP=$(/sbin/ip -o -4 addr list tun0 | awk '{print $4}' | cut -d/ -f1)


# Backup-Satellit wird am Server angemeldet
ssh -i ~/.ssh/bak_clients_knocker root@192.168.123.32 $HOST=$IP

exit 0

