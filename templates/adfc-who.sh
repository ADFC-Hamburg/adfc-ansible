#!/bin/bash


ARBEITSPLATZ="{{ groups['arbeitsplatz'] |join(' ') }}"
for PC in $ARBEITSPLATZ ; do
    echo "==== $PC ======"
    SHORT=$(echo $PC |sed -e 's/\..*//')
    OK=0
    univention-ldapsearch -LLLL "cn=${SHORT}" '(objectClass=univentionHost)' macAddress description aRecord univentionOperatingSystemVersion univentionOperatingSystem
    ping -c1 $PC >/dev/null 2>&1 && OK=1
    if [ $OK -eq 1 ] ; then
        ssh root@$PC w
        echo ''
        ssh root@$PC "LANG=C free -h"
        echo ''
        ssh root@$PC df -lh -x squashfs -x tmpfs -x devtmpfs
        echo ''
        ssh root@$PC cat /proc/cpuinfo |grep "model name" |cut -d ':' -f 2 |head -1
        echo ''
        PC_USER=$(ssh root@$PC who -u |grep -v 'root '|cut -d ' ' -f1 |head -1)
        echo ''
        univention-ldapsearch -LLL uid=${PC_USER} telephoneNumber givenName sn mailPrimaryAddress
    else
        echo AUSGESCHALTET
    fi
    echo ''
done

if [ "$1" == "--map" ] ; then
    cat <<EOF

+++++++++++++++++++++++++++++++++++++++
|  iMac           |     :             |
|          Küche  |     |     WCs     |
|                 |     ;             |
+++++++++++++ +++++     +++++++++++++++
:   Kopierer                          :
| - - - - - - - -                     |
| Zaphod               Bob     ++++++++
| Marvin               Kwaltz  | pro- |
|                              | xmox |
|                              :      |
| - - - - - - - - - - - - - - +++++++++
| Switch                              |
| Fritzbox               Testclient   |
|                        Trillian     |
|                                     |
|                                     |
+++++++++++++++++++++++++++++++++++++++
EOF
fi
