#!/bin/bash

#
# Datei wird über Ansible bereitgestellt und muss auch dort bearbeitet werden.
#

PROGNAME=$(basename $0)
error_str=""
exit_var=0
error_exit()
{
	error_str="$error_str\n${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit_var=1
}

mkdir -p /usr/local/share/ansible_downloads
cd /usr/local/share/ansible_downloads
{% for extension in firefox_extensions %}
wget -N {{ extension.url }} || error_exit "$LINENO: {{ extension.name }} could not be downloaded."
{% endfor %}

if [ $exit_var != 0 ]; then
	echo $error_str | mailx -r "{{ ansible_fqdn }}" -s "Firefox Extension Update fehlgeschlagen: {{ ansible_fqdn }}"  ak-computer@lists.hamburg.de
	exit 1
fi
