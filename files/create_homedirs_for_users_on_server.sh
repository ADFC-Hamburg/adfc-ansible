#!/bin/bash
# automatisiertes Anlegen von Homeverzeichnissen & setzen des Besitzers, der Gruppe und der Berechtigungen

# Domain Gruppenname
domain_group_name="Domain Users" #eventuell durch Group-ID abändern

# Limit der User ID
uid_limit=9999


function create_homedir {

        if [ ! -d $6 ]; then
                if [ "$3" -gt "$uid_limit" ]; then
                        echo create homedir $6 for User $1 with UID $3
                        #echo UID : $3
                        #echo homedir : $6
                        mkdir -p $6
                        chown $1:"$domain_group_name" $6
                        chmod 700 $6
                fi
        fi

}

userlist=$(getent passwd | sed -e 's/ //g')

for user in $userlist
do
#matthiasr:x:2008:5000:MatthiasRehs:/home/matthiasr:/bin/bash
create_homedir $(echo $user | sed -e 's/:/ /g')


done
