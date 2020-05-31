
function run_ansible_playbook() {
    ANSIBLE_PLAYBOOK="$1"
    echo ansible-playbook -v $ANSIBLE_PLAYBOOK > playbook.log
    touch /tmp/dyn_jitsi_playbook-$ANSIBLE_PLAYBOOK
}

function query_participants() {
    SERVER="$1"
    cat /tmp/dyn_jitsi_query_participants-${SERVER}.txt
}

function query_hetzner_server() {
    cat /tmp/dyn_jitsi_query_hetzner_server.txt
}
function clear_cache() {
    echo done
}