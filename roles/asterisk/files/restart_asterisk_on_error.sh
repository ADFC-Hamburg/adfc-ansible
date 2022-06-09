#!/bin/bash
REJECTS=$(/usr/sbin/asterisk -x "pjsip show registrations" |grep Rejected)

if [ -n "${REJECTS}" ] ; then
    /bin/systemctl restart asterisk
fi
