#!/bin/bash
# Backup-Skript mit Prüfung auf aktive Verbindung zu den Backup-Satelliten
# Ver. 0.7 vom 30.11.2019, Autor: Volker Kraeft [post@volkerkraeft.de]

# ---------- Variablen-Definition ---------------------------------------------------------

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")                      # Zeitstempel für Logdatei und Backuparchiv
LOCK_FILE="/tmp/borgback.lock"
LOG_DIR="/pfad/zum/logverz"                             # Verzeichnis für Logdaten
LOG_DATA="borgbackup_${TIMESTAMP}.log"                  # Logdatei für aktuelle Sicherung
LOGFILE="$LOG_DIR/$LOG_DATA"                            # Zur besseren Darstellung im Code ... / FIX!

CLIENTS_ONLINE_DIR="/pfad/zum/verz/bak-clients-online"  # Hier legen die Backup-Satelliten ihre Anmelde-Info ab

BAK_SECRET="borgbackup-passwort"                        # Kennwort für RepoKey
SOURCE_DIR="/pfad/zu/den/daten /datenverz"              # Zu archivierende Verzeichnisse (mit Leerzeichen getrennt)
SOURCE_EXCLUDE="*.tmp"                                  # Sicherungs-Ausnahmen (mit Leerzeichen getrennt)
REPO_PATH="~/pfad/zum/repository"                       # Pfad zum Backup-Repository auf Backup-Client
REPO_NAME="name-des-borg-repositories"                  # Name des Backup-Repositories auf Backup-Client
ARCHIVE_NAME="name-des-archivs_${TIMESTAMP}"            # Name der aktuellen Sicherung
BORG_USER="borguser"                                    # Benutzerkonto auf Backup-Client / FIX! NICHT ÄNDERN

PRUNE_DAYS="7"                                          # Anzahl der vorzuhaltenden Tagessicherungen
PRUNE_WEEKS="4"                                         # Anzahl der vorzuhaltenden Wochensicherungen
PRUNE_MONTHS="12"                                       # Anzahl der vorzuhaltenden Monatssicherungen
PRUNE_YEARS="2"                                         # Anzahl der vorzuhaltenden Jahressicherungen

MAIL_SENDER="absender@e-mail.tld"                       # Absender
MAIL_RECEIVER="empfaenger@e-mail.tld"                   # Empfänger
MAIL_PASSWD="smtp-passwort"                             # SMTP-Passwort
MAIL_SERVER="mailserver.hoster.tld"                     # SMTP-Server
MAIL_SUBJECT="ADFC Backup-Report"                       # Betreffzeile / sollte so bleiben
MAIL_BODY="Freier Text für E-Mail-Body."                # Body Text
MAIL_ATTACHM="anhang1.ext /pfad/zum/anhang2.ext"        # weitere Anhänge hier eintragen (Backup-Logdatei geht standardmäßig immer mit raus)


###########################################################################################
############ AB HIER KEINE ANPASSUNGEN MEHR ERFORDERLICH! #################################
###########################################################################################

# Per Lock-Datei verhindern, dass das Programm doppelt gestartet wird
exec 200>${LOCK_FILE} ||  exit 3
flock -n 200

# ---------- Einlesen der verbundenen Backup-Clients / Ermitteln der IP -------------------

# Ist kein Client verbunden wird auch nichts unternommen
if [ "$(ls -A $CLIENTS_ONLINE_DIR)" == "" ]; then
   exit 1
fi

# Einlesen aller Verbindungen
ALLCLIENTS=()
for CLIENT in $CLIENTS_ONLINE_DIR/*; do
    ALLCLIENTS[${#ALLCLIENTS[@]}]="$CLIENT"

    # Alle in CLIENTS_ONLINE_DIR vorhandenen Verbindungen testen, wenn Offline löschen. Nur 192er-Netz zulässig
    for CLIENT in "${ALLCLIENTS[@]}"; do
        TEST_IP=$(echo "$CLIENT" | cut -d '=' -f 2)
        if [ $(echo "$TEST_IP" | cut -d '.' -f 1) -ne 192 ]; then
           rm $CLIENT
        fi
        ping -c 3 $TEST_IP 2>&1> /dev/null
        RESULT=$?
        if [ $RESULT == 0 ]; then
           IPADDR=$TEST_IP
           ONLINE_CLIENT=$CLIENT
        else
           rm $CLIENT
        fi
    done
done

# Falls keine Verbindung funktionierte ist das Verzeinis leer. Dann Abbruch!
if [ "$(ls -A $CLIENTS_ONLINE_DIR)" == "" ]; then
   exit 2
fi



# ---------- Backup-Routine ----------------------------------------------------------------

# Repo-Init legt beim erstmaligen Aufruf ein Repository an. Weitere Aufrufe beenden sich ohne Funktion oder Fehler (Rückgabewert=2 spielt hier keine Rolle).
BORG_PASSPHRASE="$BAK_SECRET" borg init --encryption=repokey --show-rc $BORG_USER@$IPADDR:$REPO_PATH/$REPO_NAME 2>&1
BORG_PASSPHRASE="$BAK_SECRET" borg create -v -s -p -C lz4 --show-version --list --show-rc $BORG_USER@$IPADDR:$REPO_PATH/$REPO_NAME::$ARCHIVE_NAME $SOURCE_DIR --exclude $SOURCE_EXCLUDE $LOGFILE 2>&1



# ---------- Backup-Protokolle per E-Mail versenden ----------------------------------------

# Auf dem Backup-Client wird der letze Sicherungsstatus im borguser-Homedir hinterlegt. Der alte Wert wird zuvor gelöscht. Für Problemanalyse evtl. hilfreich
ssh $BORG_USER@$IPADDR -t "rm ~/BACKUP_*" 2>&1

# E-Mail bei Erfolg oder Fehlschlag versenden
if [ $? == 0 ]; then
   ssh $BORG_USER@$IPADDR -t "touch ~/BACKUP_ERFOLGREICH" # 2>&1
   sendemail -f $MAIL_SENDER -s $MAIL_SERVER -xu $MAIL_SENDER -xp $MAIL_PASSWD -t $MAIL_RECEIVER -u "$MAIL_SUBJECT - Datensicherung O.K." -m $MAIL_BODY -a $LOGFILE $MAIL_ATTACHM 2>&1
   echo "Dateiname = $ONLINE_CLIENT"
   rm $ONLINE_CLIENT
else
   ssh $BORG_USER@$IPADDR -t "touch ~/BACKUP_FEHLGESCHLAGEN" 2>&1
   sendemail -f $MAIL_SENDER -s $MAIL_SERVER -xu $MAIL_SENDER -xp $MAIL_PASSWD -t $MAIL_RECEIVER -u "$MAIL_SUBJECT - FEHLER BEI DATENSICHERUNG!!" -m $MAIL_BODY -a $LOGFILE $MAIL_ATTACHM 2>&1
   mv $ONLINE_CLIENT ${LOG_DIR}_FAILED
   exit 9
fi



# ---------- Alte Backups & Logdaten aufräumen --------------------------------------------------------

BORG_PASSPHRASE="$BAK_SECRET" borg prune $BORG_USER@$IPADDR:$REPO_PATH/$REPO_NAME --keep-within=1d --keep-daily=$PRUNE_DAYS --keep-weekly=$PRUNE_WEEKS --keep-monthly=$PRUNE_MONTHS --keep-yearly=$PRUNE_YEARS

find $LOG_DIR/* -mtime 30 -exec rm {} \;

# Lock-Datei wieder freigeben
flock -u 200

exit 0
