#!/bin/bash
computer=`dialog --radiolist "Welcher Client soll hochgefahren werden:" 0 0 3\
{% for hosts in groups['arbeitsplatz'] %}
{% if hostvars[host]['tasmota_wireless_ip'] is defined %}
	{{ hostvars[host]['inventory_hostname_short'] }} "" off\
{% endif %}
{% endfor %}

		3>&1 1>&2 2>&3`
dialog --clear
clear
{% for hosts in groups['arbeitsplatz'] %}
{% if hostvars[host]['tasmota_wireless_ip'] is defined %}
if [ $computer = {{ 
	ip_client="{{ hostvars[host]['ansible_host'] }}"
	ip_tasmota="{{ hostvars[host]['tasmota_wireless_ip'] }}"
fi
{% endif %}
{% endfor %}
