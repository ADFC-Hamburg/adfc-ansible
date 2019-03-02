#!/bin/bash

# ACHTUNG: Datei ist im Ansible Repo, bitte dort editieren

# Copyright (c) 2019 by Sven Anders

LOCK_FILE="/tmp/rsync-babelfish.lock"
LOG_FILE="/tmp/rsync-babelfish.log"

# Erstelle ein Lock File, so dass nie zwei rsyncs zeitgleich laufen
exec 200>${LOCK_FILE} ||  exit 1
flock -n 200
if [ "$?" != "0" ] ; then
    echo "FEHLER: adfc-rsync laeuft schon" >&2
    exit 1
fi

# Key Agent staten
eval $(/usr/bin/ssh-agent) >/dev/null

# Key hinzufuegen
/usr/bin/ssh-add /root/.ssh/rsync-key 2>/dev/null

# Syncen
/usr/bin/rsync --delete --exclude .snapshots -v -a babelfish:/adfc/ /adfc 2>&1 >${LOG_FILE}

# Key Agent stoppen
eval $(/usr/bin/ssh-agent -k) >/dev/null

# Lock freigeben
flock -u 200
