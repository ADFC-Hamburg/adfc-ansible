# Datei ist im ADFC Ansible

function run_ansible_playbook() {
    ANSIBLE_PLAYBOOK="$1"
    LIMIT_HOST="$2"
    ansible-playbook -v -l $LIMIT_HOST $ANSIBLE_PLAYBOOK >> playbook.log
}


function query_influx() {
    SERVER="$1"
    SELECT="$2"
    INFLUX_QUERY="SELECT ${SELECT} FROM \"jitsi_stats\" WHERE (time > now()-${TIMERANGE}) and (\"host\" ='${SERVER}')"
    JSON=$(/usr/bin/influx -username admin -password "${INFLUX_PW}" -database "${INFLUX_DB}" \
            -format json -execute "${INFLUX_QUERY}")
    echo $JSON |jq -r ".results[0].series[0].values[0][1]"
}

function query_participants() {
    SERVER="$1"
    query_influx ${SERVER} "round(mean(\"participants\"))"
}

function query_conferences() {
    SERVER="$1"
    query_influx ${SERVER} "round(mean(\"conferences\"))"
}

function query_hetzner_server() {
    CACHE_FILE="${CACHE_DIR}/servers-hcloud.json"
    if [ -f $CACHE_FILE ] ; then
        RESULT=$(find $CACHE_FILE -type f -mmin +${HCLOUD_CACHE_VALID})
        if [ -z "${RESULT}" ] ; then
            # FILE is older
            RUN=0
        else
            RUN=1
        fi
    else
        RUN=1
    fi
    if [ "$RUN" == "1" ] ; then
        curl --silent --header "${HCLOUD_API_HEADER}" "${HCLOUD_API_SERVERS}" > $CACHE_FILE
        chmod 600 $CACHE_FILE
    fi
    jq -r '.servers' <$CACHE_FILE
}
function clear_cache() {
    CACHE_FILE="${CACHE_DIR}/servers-hcloud.json"
    rm "${CACHE_FILE}"
}