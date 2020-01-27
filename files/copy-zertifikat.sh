#!/bin/bash
Z_AKTION=$1
Z_UID=$2
Z_DN=$3
Z_CERTPATH=$4
FROMMAIL=it-support@hamburg.adfc.de
PW_FILE="${Z_CERTPATH}/${Z_UID}/${Z_UID}-p12-password.txt" 
function copy_zert {
    EMAIL=$(univention-ldapsearch -LLL uid=$Z_UID mailPrimaryAddress |grep mailPrimaryAddress | cut -d ' ' -f 2)
    Z_HOME="/home/${Z_UID}/adfc-zertifikate"
    mkdir -p $Z_HOME
    Z_FILE="$Z_HOME/${Z_UID}$(date +%Y%m%d).p12"
    cp "${Z_CERTPATH}/${Z_UID}/${Z_UID}.p12"  $Z_FILE
    chown -R "${Z_UID}" "${Z_HOME}"
    mailx -r "${FROMMAIL}" -s "Neues Zertikat" $EMAIL <<EOF

AUTOMATISCH ERZEUGTE E-MAIL

Für dich wurde ein Zertifikat für den Remote-Zugang erstellt.

Dieses liegt unter:

$Z_HOME

und muss von dir auf einem sicheren Weg (möglichst per USB Stick) zu dir nach Hause kopiert werden.

Das Passwort für das Zertifikat lautet:

$(cat $PW_FILE)

Eine Anleitung zum Einspielen findet sich unter

https://wiki.hamburg.adfc.de/doku.php?id=ak-pc:zugriff_von_aussen_ueber_zertifikat

Bitte lösche diese E-Mail und sämtliche Kopien des Zertifikats nachdem du das Zertifikat eingespielt hast.

EOF

}

if [ "${Z_AKTION}" == "create" ] ; then
    copy_zert
fi
if [ "${Z_AKTION}" == "renew" ] ; then
    copy_zert
fi
