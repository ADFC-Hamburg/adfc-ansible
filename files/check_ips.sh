#!/bin/bash

##
## Script wird über ansible deployed
##

ping_targets="192.168.123.32"
failed_hosts=""

for i in $ping_targets
do
   ping -c 1 $i > /dev/null
   if [ $? -ne 0 ]; then
      if [ "$failed_hosts" == "" ]; then
         failed_hosts="$i"
      else
         failed_hosts="$failed_hosts, $i"
      fi
   fi
done

if [ "$failed_hosts" != "" ]; then
   echo $failed_hosts| mailx -r "proxmox01" -s "Host nicht erreichbar:"  ak-computer@lists.hamburg.adfc.de
fi
