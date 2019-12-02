#!/bin/bash
# Backup-Skript mit Prüfung auf aktive Verbindung zu den Backup-Satelliten
# Ver. 0.7 vom 30.11.2019, Autor: Volker Kraeft [post@volkerkraeft.de]

# ---------- Variablen-Definition ---------------------------------------------------------

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")                   # Zeitstempel für Logdatei und Backuparchiv
LOG_DIR="/pfad/zum/logverz"                          # Verzeichnis für Logdaten
LOG_DATA="borgbackup_${TIMESTAMP}.log"               # Logdatei für aktuelle Sicherung
LOGFILE="$LOG_DIR/$LOG_DATA"                         # Zur besserern Darstellung im Code ... / FIX!

CL_ONLINE_DIR="/pfad/zum/verz/bak-clients-online"    # Hier legen die Backup-Satelliten ihre Anmelde-Info ab

SECRET="borgbackup-passwort"                         # Kennwort für RepoKey
SOURCE_DIR="/pfad/zu/den/daten /datenverz"           # Zu archivierende Verzeichnisse (mit Leerzeichen getrennt)
SOURCE_EXCL="*.tmp"                                  # Sicherungs-Ausnahmen (mit Leerzeichen getrennt)
REPO_PATH="~/pfad/zum/repository"                    # Pfad zum Backup-Repository auf Backup-Client
REPO_NAME="name-des-borg-repositories"               # Name des Backup-Repositories auf Backup-Client
ARCHIVE_NAME="name-des-archivs_${TIMESTAMP}"         # Name der aktuellen Sicherung
BORG_USER="borguser"                                 # Benutzerkonto auf Backup-Client / FIX! NICHT ÄNDERN

PRUNE_D="7"                                          # Anzahl der vorzuhaltenden Tagessicherungen
PRUNE_W="4"                                          # Anzahl der vorzuhaltenden Wochensicherungen
PRUNE_M="12"                                         # Anzahl der vorzuhaltenden Monatssicherungen
PRUNE_Y="2"                                          # Anzahl der vorzuhaltenden Jahressicherungen

M_SND="absender@e-mail.tld"                          # Absender
M_RCV="empfaenger@e-mail.tld"                        # Empfänger
M_PWD="smtp-passwort"                                # SMTP-Passwort
M_SVR="mailserver.hoster.tld"                        # SMTP-Server
M_SUB="Backup-Report"                                # Betreffzeile / sollte so bleiben
M_BDY="Freier Text für E-Mail-Body."                 # Body Text
M_ATT="anhang1.ext /pfad/zum/anhang2.ext"            # weitere Anhänge hier eintragen (Backup-Logdatei geht standardmäßig immer mit raus)



###########################################################################################
############ AB HIER KEINE ANPASSUNGEN MEHR ERFORDERLICH! #################################
###########################################################################################


# ---------- Einlesen der verbundenen Backup-Clients / Ermitteln der IP -------------------

# Ist kein Client verbunden wird auch nichts unternommen
if [ "$(ls -A $CL_ONLINE_DIR)" ]; then
   MACHE="WEITER"
else
   exit 1
fi

# Einlesen aller Verbindungen
ALLCLIENTS=()
for FILES in $CL_ONLINE_DIR/*; do
    ALLCLIENTS[${#ALLCLIENTS[@]}]="$FILES"
done

# Alle in CL_ONLINE_DIR vorhandenen Verbindungen testen, wenn Offline löschen. Nur 192er-Netz zulässig
for FILES in "${ALLCLIENTS[@]}"; do
    TEST_IP=$(echo "$FILES" | cut -d '=' -f 2)
    if [ $(echo "$TEST_IP" | cut -d '.' -f 1) -ne 192 ]; then
       rm $FILES
    fi
    ping -c 3 $TEST_IP 2>&1> /dev/null
    RESULT=$?
    if [ $RESULT == 0 ]; then
       IPADDR=$TEST_IP
       ONLINE_FILE=$FILES
    else
       rm $FILES
    fi
done

# Falls keine Verbindung funktionierte ist das Verzeinis leer. Dann Abbruch!
if [ "$(ls -A $CL_ONLINE_DIR)" ]; then
   MACHE="WEITER"
else
   exit 2
fi



# ---------- Backup-Routine ----------------------------------------------------------------

# Repo-Init legt beim erstmaligen Aufruf ein Repository an. Weitere Aufrufe beenden sich ohne Funktion oder Fehler (Rückgabewert=2 spielt hier keine Rolle).
BORG_PASSPHRASE="$SECRET" borg init --encryption=repokey --show-rc $BORG_USER@$IPADDR:$REPO_PATH/$REPO_NAME 2>&1
BORG_PASSPHRASE="$SECRET" borg create -v -s -p -C lz4 --show-version --list --show-rc $BORG_USER@$IPADDR:$REPO_PATH/$REPO_NAME::$ARCHIVE_NAME $SOURCE_DIR --exclude $SOURCE_EXCL $LOGFILE 2>&1



# ---------- Backup-Protokolle per E-Mail versenden ----------------------------------------

# Auf dem Backup-Client wird der letze Sicherungsstatus im borguser-Homedir hinterlegt. Der alte Wert wird zuvor gelöscht. Für Problemanalyse evtl. hilfreich
ssh $BORG_USER@$IPADDR -t "rm ~/BACKUP_*" 2>&1

# E-Mail bei Erfolg oder Fehlschlag versenden
if [ $? == 0 ]; then
   ssh $BORG_USER@$IPADDR -t "touch ~/BACKUP_ERFOLGREICH" # 2>&1
   sendemail -f $M_SND -s $M_SVR -xu $M_SND -xp $M_PWD -t $M_RCV -u "$M_SUB - Datensicherung O.K." -m $M_BDY -a $LOGFILE $M_ATT 2>&1
   echo "Dateiname = $ONLINE_FILE"
   rm $ONLINE_FILE
else
   ssh $BORG_USER@$IPADDR -t "touch ~/BACKUP_FEHLGESCHLAGEN" 2>&1
   sendemail -f $M_SND -s $M_SVR -xu $M_SND -xp $M_PWD -t $M_RCV -u "$M_SUB - FEHLER BEI DATENSICHERUNG!!" -m $M_BDY -a $LOGFILE $M_ATT 2>&1
   mv $ONLINE_FILE ${LOG_DIR}_FAILED
   exit 9
fi



# ---------- Alte Backups & Logdaten aufräumen --------------------------------------------------------

BORG_PASSPHRASE="$SECRET" borg prune $BORG_USER@$IPADDR:$REPO_PATH/$REPO_NAME --keep-within=1d --keep-daily=$PRUNE_D --keep-weekly=$PRUNE_W --keep-monthly=$PRUNE_M --keep-yearly=$PRUNE_Y

find $LOG_DIR/* -mtime 30 -exec rm {} \;

exit 0
