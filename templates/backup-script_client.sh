#!/bin/bash

# ACHTUNG: Datei ist im Ansible Repo, bitte dort editieren
timecode=$(date '+%Y-%m-%d-%H-%M-%S')
logfile=/tmp/$timecode-borglog.txt

backup_target={{ local_borg_repo }}
backup_source={{ adfc_borg_server }}

# öffne vpn - Verbindung
vpnc /etc/vpnc/vpnc.conf

# rsync beider Verzeichnisse
#borg init {{ adfc_borg_server }} + some fancy options + $timecode >> $logfile

# trenne vpn - Verbindung
vpnc-disconnect

mail -s 'Backup-Log from {{ ansible_host }}' {{ adfc_notification_email }}  < $logfile

#rm $logfile




