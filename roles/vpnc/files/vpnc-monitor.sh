#!/bin/bash

UNIT=$1
PING_ADDR=$2
STATUSFILE=/run/vpnc-monitor.down

JSON=$(journalctl -u $UNIT -n 1 -o json)
MESSAGE=$(echo $JSON |jq -r .MESSAGE)

function restart_vpn
{
    killall -u borguser
    systemctl restart $UNIT
}

function no_ping
{
    if [ ! -f $STATUSFILE ] ; then
        touch $STATUSFILE
    fi
    OUT=$(find $STATUSFILE -mmin +10)
    if [ -n "${OUT}" ] ; then
        restart_vpn
    fi
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
ping -c 2 $PING_ADDR 2>&1> /dev/null

if [ $? -ne 0 ]; then
    restart_vpn
else
    if [ -f $STATUSFILE ] ; then
        rm $STATUSFILE
    fi
fi
