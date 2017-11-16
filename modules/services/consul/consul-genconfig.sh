#!/bin/bash

DN="$1"
EXPECT="$2"
DC="$3"
ENDPOINTS="$4"
CONF="$5"

PROGRAM_NAME=$(basename $0)

[ "$#" -ne 5 ] && echo "$PROGRAM_NAME: wrong number of argument(s)" && exit 1

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
        "start_join": [ $hosts ]
}
EOF

