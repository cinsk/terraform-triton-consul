#!/bin/bash

DN="$1"
EXPECT="$2"
DC="$3"
ENDPOINTS="$4"
INTERFACE="$5"
CONF="$6"

PROGRAM_NAME=$(basename $0)

[ "$#" -ne 6 ] && echo "$PROGRAM_NAME: wrong number of argument(s)" && exit 1

hosts=""
while read ln; do
    hosts="${hosts},\"${ln}\""
done < <(sort -u "$ENDPOINTS")
hosts=${hosts#,}

cat > "$CONF" <<EOF
{
        "datacenter": "$DC",
        "server": true,
        "bootstrap_expect": $EXPECT,
        "data_dir": "/var/run/consul",
        "advertise_addr": "{{ GetInterfaceIP \"$INTERFACE\" }}",
        "start_join": [ $hosts ]
}
EOF

