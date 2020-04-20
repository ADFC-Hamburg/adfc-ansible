#!/bin/bash
# Datei im Git/Ansible, bitte dort bearbeiten
#
#
rm -rf /tmp/smbbackup >/dev/null
mkdir /tmp/smbbackup >/dev/null
/usr/bin/smbclient -U Administrator   -I 192.168.142.10 '\\Win7Pro_VM\C$' $(cat /etc/win7pro-admin.secret) -c 'cd adfc ; lcd /tmp/smbbackup; prompt; recurse; mget *; exit' >/dev/null 2>&1
if [ "$?" != "0" ] ; then
    echo "smbclient: Fehler beim Backup" >&2
fi
/usr/bin/rsync -a -r --delete /tmp/smbbackup/ /adfc/Computer/Datensicherung/Vereinsverwaltung >/dev/null
rm -rf /tmp/smbbackup >/dev/null
