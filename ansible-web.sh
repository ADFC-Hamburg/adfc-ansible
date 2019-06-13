#!/bin/bash



ARG=$1
if [ -z "$ARG" ] ; then
   echo 'please spezify a hostname' >&2
   exit 1
fi


if [ ${ARG:0:10} == "host_vars/" ] ; then
        echo Found host_vars-file as argument
        ARG=${ARG:10:${#ARG}}
        ARG=${ARG:0:${#ARG} - 4}
        echo revised argument: $ARG

fi

JQ=$(which jq)


if [ -z "$JQ" ] ; then
   echo 'jq not found, please install it with "apt install jq"' >&2
   exit 2
fi

JSON=$(ansible-inventory  --host=${ARG})
ANSIBLE_HOST=$(echo $JSON |$JQ -r .ansible_host )
ANSIBLE_PORT=$(echo $JSON |$JQ -r '.ansible_port // 822' )
ANSIBLE_USER=$(echo $JSON |$JQ -r '.ansible_user // "root"' )
ANSIBLE_ARGS=$(echo $JSON |$JQ -r '.ansible_ssh_common_args // ""')
ANSIBLE_WEB_PORT=$(echo $JSON |$JQ -r '.ansible_web_port // "8080"' )
ANSIBLE_WEB_SUBDIR=$(echo $JSON |$JQ -r '.ansible_web_subdir // ""' )


echo starting webbrowser with address https://127.0.0.1:1$ANSIBLE_WEB_PORT$ANSIBLE_WEB_SUBDIR
echo remote port: $ANSIBLE_WEB_PORT, locale port: 1$ANSIBLE_WEB_PORT
python -mwebbrowser https://127.0.0.1:1$ANSIBLE_WEB_PORT$ANSIBLE_WEB_SUBDIR &

echo connecting to host $ARG ...
ssh -p $ANSIBLE_PORT -L 1$ANSIBLE_WEB_PORT:$ANSIBLE_HOST:$ANSIBLE_WEB_PORT root@babelfish.spdns.de