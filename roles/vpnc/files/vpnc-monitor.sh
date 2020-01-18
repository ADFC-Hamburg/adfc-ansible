#!/bin/bash

UNIT=$1
PING_ADDR=$2

JSON=$(journalctl -u $UNIT -n 1 -o json)
MESSAGE=$(echo $JSON |jq -r .MESSAGE)

function restart_vpn
{
    killall -u borguser
    systemctl restart $UNIT
}

case "${MESSAGE}" in
    "vpnc: recvfrom: No route to host")
        restart_vpn
        exit 0
    ;;
    "vpnc: HMAC mismatch in ESP mode")
        restart_vpn
        exit 0
        ;;
esac
ping -c 1 $PING_ADDR 2>&1> /dev/null

if [ $? -ne 0 ]; then
    restart_vpn
fi
