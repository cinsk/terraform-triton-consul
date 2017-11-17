#!/bin/bash

log() {
    echo "$(date -Iseconds) $*"
}

exec >& /var/log/terraform.provision.log

DN="${CONSUL_DOMAIN_NAME}"
EXPECT="${CONSUL_EXPECTED}"
DC="${CONSUL_DATACENTER}"
INTERFACE="${CONSUL_INTERFACE}"

CONSUL_DOWNLOAD="https://releases.hashicorp.com/consul/1.0.0/consul_1.0.0_linux_amd64.zip?_ga=2.12055668.1992751745.1510776303-1473774429.1509575118"

CONSUL_AR="/tmp/consul.$$$$.zip"

trap "rm -f $CONSUL_AR" EXIT

retry=3
count=0

while [ "$count" -le "$retry" ]; do
    wget -nv -O "$CONSUL_AR" "$CONSUL_DOWNLOAD"
    ret="$?"
    if [ "$ret" -eq 0 -a -r "$CONSUL_AR" ]; then
        log "downloading consul(1) successful" 
        break
    fi
    count=$((count + 1))
done

if [ "$count" -ge "$retry" ]; then
    log "downloading consul failed for $count times. aborting"
    exit 1
fi

mkdir -p /usr/local/bin
cd /usr/local/bin

unzip "$CONSUL_AR"

# yum install -y tmux screen

chmod +x /var/local/consul-launcher.sh
chmod +x /var/local/consul-genconfig.sh
chmod +x /var/local/consul-reconfig.sh

nohup /var/local/consul-launcher.sh "$DN" "$EXPECT" "$DC" "$INTERFACE" &
nohup /var/local/consul-reconfig.sh "$DN" "$EXPECT" "$DC" "$INTERFACE" &

while :; do
    if [ -f /var/run/consul-launcher.pid -a -f /var/run/consul-reconfig.pid ]; then
        break
    fi
    log "waiting for consul-launcher and consul-reconfig"
    sleep 1
done

log "consul-launcher and consul-reconfig seems running"
ps -ef | grep consul

log "$0 finished"
