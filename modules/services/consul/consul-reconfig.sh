#!/bin/bash

# Generate new consul configuration periodically, compare it with the current one,
# if they are different, replace the current one to the new one, and notify consul(1)
# to update its configuration.

PROGRAM_NAME=$(basename $0)
ENDPOINTS=/tmp/endpoints.$$

PID_FILE=/var/run/consul-reconfig.pid
CONSUL_PIDFILE=/var/run/consul.pid
CONSUL_CONF=/var/local/consul.conf.json
TMPCONF=/tmp/consul.conf.$$.json

endpoints() {
    local dn="$1"
    dig +noall +aaonly +answer "$dn" | awk '{ print $5 }'
}

log() {
    echo "$(date -Iseconds) $*"
}

error() {
    local exitcode="$1"
    echo "$PROGRAM_NAME: $*" 1>&2
    [ "$exitcode" -ne 0 ] && exit "$exitcode"
}

DN="$1"
EXPECT="$2"
DC="$3"

if [ "$#" -ne 3 ]; then
    error 0 "wrong number of argument(s)"
    error 1 "usage: $PROGRAM_NAME CONSUL-DOMAIN-NAME EXPECTED-INSTANCES DATA-CENTER"
fi

trap "rm -f $TMPCONF $ENDPOINTS" EXIT

exec >& /var/log/consul.reconfig.log
echo "$$" > "$PID_FILE"

log "$PROGRAM_NAME started, pidfile = $PID_FILE"

while :; do
    sleep 60
    
    running=$(endpoints "$DN" | tee "$ENDPOINTS" | wc -l)
    if [ "$running" -lt "$EXPECT" ]; then
        log "not enough instance found (current=$running)"
        continue
    fi

    # Generate new consul(1) configuration
    /var/local/consul-genconfig.sh "$DN" "$EXPECT" "$DC" "$ENDPOINTS" "$TMPCONF"

    if cmp "$TMPCONF" "$CONSUL_CONF"; then
        # If the new configuration is the same as the current one, do nothing
        continue
    fi

    if [ -r "$CONSUL_PIDFILE" ]; then
        log "replacing consul(1) configuration"
        mv "$TMPCONF" "$CONSUL_CONF"
        
        log "sending SIGHUP to consul to reconfigure itself"
        kill -HUP $(cat "$CONSUL_PIDFILE")
    else
        log "consul pid file not found - do nothing"
    fi
done
      
