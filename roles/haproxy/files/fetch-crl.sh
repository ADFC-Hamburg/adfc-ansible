#!/bin/bash
TMPFILE=$( mktemp )
DESTFILE=/etc/haproxy/cert_auth/crl.pem
OK=0
/usr/bin/wget -q http://192.168.123.32/ucsCA.crl -O - |/usr/bin/openssl crl -inform der  -outform pem -out $TMPFILE && OK=1
if [ "${OK}" == "1" ]; then
    DIFF=1
    diff $TMPFILE $DESTFILE >/dev/null && DIFF=0
    if [ "${DIFF}" == "1" ]; then
        cp $TMPFILE $DESTFILE
        systemctl restart haproxy
    fi
fi
rm $TMPFILE