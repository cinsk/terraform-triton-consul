#!/bin/bash

#
# Launch consul(1), if consul(1) somehow crashes, launch again repeatedly.
#

DN="$1"
EXPECT="$2"
DC="$3"

PROGRAM_NAME=$(basename "$0")
ENDPOINTS=/tmp/endpoints.$$
PIDFILE=/var/run/consul-launcher.pid
CONSUL_CONF=/var/local/consul.conf.json
endpoints() {
    local dn="$1"
    dig +noall +aaonly +answer "$dn" | awk '{ print $5 }'
}

log() {
    echo "$(date -Iseconds) $*"
}

exec >& /var/log/consul.launcher.log

if [ "$#" -ne 3 ]; then
    log "wrong number of argument(s)"
    log "Usage: $PROGRAM_NAME CONSUL-DOMAIN-NAME EXPECT DATA-CENTER"
    exit 1
fi

echo "$$" > "$PIDFILE"
log "$PROGRAM_NAME started. pid = $$, saved to $PIDFILE"

trap "rm -f $ENDPOINTS $PIDFILE" EXIT

while :; do
    while :; do
        sleep 5
        running=$(endpoints "$DN" | tee "$ENDPOINTS" | wc -l)
        if [ "$running" -ge "$EXPECT" ]; then
            log "Found enough($running >= $EXPECT) instances"
            break
        fi
        log "Waiting for more instances (current=$running, expected=$EXPECT) coming up..."
    done

    log "generating consul configuration in $CONSUL_CONF"
    /var/local/consul-genconfig.sh "$DN" "$EXPECT" "$DC" "$ENDPOINTS" "$CONSUL_CONF"

    cmdline=("consul" "agent" "-config-file=/var/local/consul.conf.json" "-pid-file=/var/run/consul.pid")
    log "launching consul: ${cmdline[*]}"
    "${cmdline[@]}" >>/var/log/consul.log 2>&1
    ret="$?"
    
    if [ "$ret" -ne 0 ]; then
        log "CONSUL exited with $ret"
        echo -e "\f" >>/var/log/consul.log
    fi
done
    
