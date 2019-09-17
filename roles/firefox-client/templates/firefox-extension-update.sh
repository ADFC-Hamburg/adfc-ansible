#!/bin/bash

#
# Datei wird über Ansible bereitgestellt und muss auch dort bearbeitet werden.
#

if cd /usr/local/share/ansible_downloads; then
downloads=({% for extension in firefox_extensions %}
"`wget -N {{ extension.url }}`"{% endfor %}); fi

for download in "${downloads[@]}"; do
  if [ -z "$download " ]
  then echo Something failed.
       all_succeeded=0
       break
  fi
done
