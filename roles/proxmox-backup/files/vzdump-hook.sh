#!/bin/bash

# Datei ist im GIT / Ansible

# Aufruf:
#
# job-start
# backup-start snapshot 102
# pre-stop snapshot 102
# pre-restart snapshot 102
# post-restart snapshot 102
# backup-end snapshot 102
# log-end snapshot 102
# job-end

# Environment:
#  DUMPDIR="/zfsStorage/backups/dump"
#  HOSTNAME="Win7Pro"
#  LOGFILE="/zfsStorage/backups/dump/vzdump-qemu-102-2020_02_01-04_00_01.log"
#  LVM_SUPPRESS_FD_WARNINGS="1"
#  SHLVL="1"
#  STOREID="zfsBackups"
#  TARFILE="/zfsStorage/backups/dump/vzdump-qemu-102-2020_02_01-04_00_01.vma.lzo"
#  VMTYPE="qemu"

# Die Backups werden Automatisch von Proxmox gelöscht, siehe:
#   Datacenter/Storage/YOUR_BACKUP_STORAGE: max backups"

AKTION=$1

if [ $AKTION = "backup-end" ] ; then
    ART=$2
    VZID=$3
    if [ $VZID != "100" ] ; then
        scp -q -i /root/.ssh/proxmox-backup $TARFILE root@192.168.123.32:/adfc/Computer/Datensicherung/Proxmox/
    fi
fi
if [ $AKTION = "log-end" ] ; then
    ART=$2
    VZID=$3
    if [ $VZID != "100" ] ; then
        tar cfz /tmp/backup-etc.tgz -C /etc .
        scp -q -i /root/.ssh/proxmox-backup $LOGFILE root@192.168.123.32:/adfc/Computer/Datensicherung/Proxmox/
        scp -q -i /root/.ssh/proxmox-backup /tmp/backup-etc.tgz root@192.168.123.32:/adfc/Computer/Datensicherung/Proxmox/
        rm /tmp/backup-etc.tgz
    fi
fi
