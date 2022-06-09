#!/bin/bash
REJECTS=$(/usr/sbin/asterisk -x "pjsip show registrations" |grep Rejected)

if [ -n "${REJECTS}" ] ; then
    /usr/bin/logger "Astersik pjsip cron restart"
    /bin/systemctl restart asterisk
fi
