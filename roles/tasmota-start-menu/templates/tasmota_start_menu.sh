#!/bin/bash
computer=`dialog --radiolist "Welcher Client soll hochgefahren werden:" 0 0 8\
{% for host in groups['arbeitsplatz'] %}
{% if hostvars[host]['tasmota_wireless_ip'] is defined and hostvars[host]['ansible_host_macaddress'] != 'ff:ff:ff:ff:ff:ff' %}
	{{ hostvars[host]['inventory_hostname_short'] }} "" off\
{% endif %}
{% endfor %}
		3>&1 1>&2 2>&3`
dialog --clear
clear
{% for host in groups['arbeitsplatz'] %}
{% if hostvars[host]['tasmota_wireless_ip'] is defined and hostvars[host]['ansible_host_macaddress'] != 'ff:ff:ff:ff:ff:ff' %}
if [ $computer = {{ hostvars[host]['inventory_hostname_short'] }} ]; then
	ip_client="{{ hostvars[host]['ansible_host'] }}"
	ip_tasmota="{{ hostvars[host]['tasmota_wireless_ip'] }}"
	mac_client="{{ hostvars[host]['ansible_host_macaddress'] }}"
fi
{% endif %}
{% endfor %}

if p=$(ping -c1 -W1 $ip_client | grep -i '0 received'); then
	echo "Der Client $computer reagiert nicht."
	if a=$(curl -s http://$ip_tasmota/cm?cmnd=power | grep -i '"ON"'); then
		wakeonlan $mac_client &> /dev/null
		echo "Der client wurde aufgeweckt"
		sleep 5
		if b=$(ping -c1 -W1 $ip_client | grep -i '0 received'); then
			echo "Die Steckdose war eingeschaltet. Sie wird nun ausgeschaltet und nach einer Minute wieder eingeschaltet. Der Client $computer sollte dann starten."
			curl -s "http://$ip_tasmota/cm?cmnd=Power+Off" &> /dev/null
			sleep 60
		else
			echo "Der client $computer hat geschlafen und wurde erfolgreich aufgeweckt"
			sleep 5
			exit
		fi
	else	
		echo "Die Steckdose wird jetzt eingeschaltet. Bitte ein paar Sekunden warten bis der Client hochgefahren ist und dann die Verbindung über guacamole aufbauen."
		curl -s "http://$ip_tasmota/cm?cmnd=Power+On" &> /dev/null
		sleep 5
		echo "Dieses Programm wird jetzt automatisch beendet."
		sleep 5
	fi
else
	echo "Der Client $computer läuft bereits. Bitte bauen Sie eine Verbindung über guacamole auf."
	echo "Dieses Programm wird jetzt automatisch beendet."
	sleep 5
fi
