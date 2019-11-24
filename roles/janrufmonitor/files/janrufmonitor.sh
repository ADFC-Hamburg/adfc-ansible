#!/bin/bash
JUSERDIR="/opt/janrufmonitor/users/$USER"
JHOMEDIR="$HOME/.config/janrufmonitor"

function replaceDirs {
    JUSER="N"
    if [ -L "${JUSERDIR}" ] ; then
        JUSER="L"
    else
        if [ -d "${JUSERDIR}" ] ; then
            JUSER="D"
        fi
    fi

    JHOME="N"
    if [ -e "${JHOMEDIR}" ] ; then
        JHOME="J"
    fi
    if [ "${JUSER}${JHOME}" == "DN" ] ; then
        # Nach dem ersten Start bleibt ein Direcory zurück, wir erstzen es durch einen Sysmlink
        mv "$JUSERDIR" "$JHOMEDIR"
        ln -s "$JHOMEDIR" "$JUSERDIR"
        /bin/sed -i -e "s/\/opt\/janrufmonitor\/users\/$USER\//\/home\/$USER\/.config\/janrufmonitor\//" $JHOMEDIR/.paths
    elif [ "${JUSER}${JHOME}" == "LN" ] ; then
        # Der Link ist da aber das Verzeichnis beim user wurde geloescht
        # wir loeschen den Link
        rm "$JUSERDIR"
    elif [ "${JUSER}${JHOME}" == "NJ" ] ; then 
        # Der Link fehlt
        ln -s "$JHOMEDIR" "$JUSERDIR"
    elif [ "${JUSER}${JHOME}" == "DJ" ] ; then 
        # Konfig ist da aber auch ein neues Directory
        # lösche das neue directory
        rm -rf "$JUSERDIR"
        ln -s "$JHOMEDIR" "$JUSERDIR"
    fi
    # Bei NN starten wir Jam damit das Verzeichnis angelegt wird, im Anschluss haben wir DN
    # Bei LJ ist Normalbetrieb wir brauchen nichts zu tun
}

function runJam {
    cd /opt/janrufmonitor
    java -Djam.multiuser=true -Djava.library.path=. -cp jamapi.jar:jam.jar:jamlinux.jar:hsqldb.jar:i18n.jar:swt.jar:jffix.jar de.janrufmonitor.application.RunUI
}

replaceDirs
runJam
replaceDirs
