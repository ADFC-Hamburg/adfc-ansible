#!/bin/bash
#  Ansible Managed
A=$(kdialog --title "Installation" --progressbar "Check for a new version of chromium" )
qdbus $A showCancelButton false
qdbus $A Set "" "value" 10
/usr/local/bin/update-chromium-latest
qdbus $A Set "" "value" 100
qdbus $A close
exec /usr/local/chromium/unzip/chrome-linux/chrome --password-store=latest $*