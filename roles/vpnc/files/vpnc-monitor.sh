#!/bin/bash

UNIT=$1
PING_ADDR=$2

JSON=$(journalctl -u $UNIT -n 1 -o json)
MESSAGE=$(echo $JSON |jq -r .MESSAGE)

case "${MESSAGE}" in
    "vpnc: recvfrom: No route to host")
        systemctl restart $UNIT
        exit 0
    ;;
    "vpnc: HMAC mismatch in ESP mode")
        systemctl restart $UNIT
        exit 0
        ;;
    *)
        exit 0
        ;;

esac
