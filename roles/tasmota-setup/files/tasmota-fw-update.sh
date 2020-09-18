#!/bin/bash
IP=$1

RULE1_TXT="ON Energy#Power>6 DO Backlog Rule2 ON; Rule1 OFF ENDON"
RULE2_TXT="ON Energy#Power<6 DO Backlog Power1 OFF; Rule1 ON; Rule2 OFF ENDON"

urlencode() {
    # urlencode <string>

    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:$i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LC_COLLATE=$old_lc_collate
}
URLE_RULE1_TXT=$( urlencode "$RULE1_TXT" )
URLE_RULE2_TXT=$( urlencode "$RULE2_TXT" )

echo $URLE_RULE1_TXT
echo $URLE_RULE2_TXT

TEXT=$(curl -s "http://${IP}")
V=$(echo $TEXT |sed 's/.*Tasmota \(8.*\) by Theo .*/\1/')
if [ "${V}" == "8.1.0.2" ] ; then
   curl -s "http://${IP}/u1?o=http%3A%2F%2Fsidweb.nl%2Ftasmota%2Ftasmota.bin"  --insecure
   while [ "${V}" != "8.4.0.3" ] ; do
       sleep 2
       ping -c1 $IP
       TEXT=$(curl -s "http://${IP}")
       V=$(echo $TEXT |sed 's/.*Tasmota \(8.*\) by Theo .*/\1/')
       echo $V $TEXT
       MIN=$(echo $TEXT |grep 'MINIMAL firmware')
       if [ -z "$MIN" ] ; then
           V="min${V}"
       fi
   done
fi
echo Firmware is current $V
GOSOUND_CFG=$(echo $TEXT |grep "Gosund SP1")
if [ -z "$GOSOUND_CFG" ] ; then
    curl "http://${IP}/md?g99=54&g0=0&g1=0&g2=0&g3=0&g4=0&g5=0&g12=0&g13=0&g14=0&g15=0&g16=0&g17=0&save="
else
    echo Cfg is okay
fi
RULE=$(curl "http://${IP}/cm?cmnd=Rule1")
ST_RULE1_STATUS=$( echo $RULE |jq -r .Rule1)
ST_RULE1_TXT=$( echo $RULE |jq -r .Rules)

RULE=$(curl "http://${IP}/cm?cmnd=Rule2")
ST_RULE2_STATUS=$( echo $RULE |jq -r .Rule2)
ST_RULE2_TXT=$( echo $RULE |jq -r .Rules)

if [ "$ST_RULE1_TXT" != "$RULE1_TXT" ] ; then
    echo Old Rule1: $RULE1_TXT
    echo Setzte Rule1
    curl "http://${IP}/cm?cmnd=Rule1%20${URLE_RULE1_TXT}"
fi
if [ "$ST_RULE2_TXT" != "$RULE2_TXT" ] ; then
    echo Old Rule2: $RULE1_TXT
    echo Setzte Rule2
    curl "http://${IP}/cm?cmnd=Rule2%20${URLE_RULE2_TXT}"
fi

if [ "$RULE1_STATUS" = "OFF" ] && [ "$RULE2_STATUS" = "OFF" ] ; then
    curl "http://${IP}/cm?cmnd=Rule1%20ON"
fi

