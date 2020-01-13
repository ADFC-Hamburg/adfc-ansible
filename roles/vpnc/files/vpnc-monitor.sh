#!/bin/bash

UNIT=$1
PING_ADDR=$2

JSON=$(journalctl -u $UNIT -n 1 -o json)
MESSAGE=$(echo $JSON |jq -r .MESSAGE)

if [ "${MESSAGE}" =  "vpnc: recvfrom: No route to host" ] ; then
    systemctl restart $UNIT
    exit 0
fi
