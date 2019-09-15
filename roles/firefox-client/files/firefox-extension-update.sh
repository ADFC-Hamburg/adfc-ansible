#!/bin/bash

#
# Datei wird über Ansible bereitgestellt und muss auch dort bearbeitet werden.
#

if cd /usr/local/share/ansible_downloads; then
downloads=("`wget -N https://addons.mozilla.org/firefox/downloads/file/3060290/https_everywhere.xpi`"
"`wget -N https://addons.mozilla.org/firefox/downloads/file/3397453/i_dont_care_about_cookies.xpi`"
"`wget -N https://addons.mozilla.org/firefox/downloads/file/1166954/ublock_origin.xpi`"); fi

for download in "${downloads[@]}"; do
  if [ -z "$download " ]
  then echo Something failed.
       all_succeeded=0
       break
  fi
done
