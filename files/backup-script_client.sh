#!/bin/bash

# ACHTUNG: Datei ist im Ansible Repo, bitte dort editieren

backup_target=/usr/local/share/backupdisk
backup_source=/usr/local/share/backup_source
# mount backup-Volume
mount $backup_target #Konfiguration über fstab


# öffne vpn - Verbindung
vpnc /etc/vpnc/vpnc.conf

# mount server-backup-volume
mount $backup_source #Konfiguration über fstab

# rsync beider Verzeichnisse
rsync $backup_source $backup_target #bzw über entsprechenden borgbackup Befehl

# unmount beider volumes
umount $backup_source
umount $backup_target

# trenne vpn - Verbindung
vpnc-disconnect





