#!/usr/bin/env bash

# Note: Base UID is 100000

set -eux

TEMPLATE_CT=102
INSTANCE_CT=10000
INSTANCE_NAME=tx
ADDRESS=22
USERNAME=karl

HOST_DATA=/home/data

pct clone $TEMPLATE_CT $INSTANCE_CT --full 1
pct resize $INSTANCE_CT rootfs 10G
pct set $INSTANCE_CT \
    --onboot=1 \
    --hostname ${INSTANCE_NAME} \
    --memory 16384 \
    --net0 name=eth0,hwaddr=12:4B:53:00:00:${ADDRESS},ip=dhcp,ip6=dhcp,bridge=vmbr0
mkdir -p /home/data/${INSTANCE_NAME}/home
chown 100000:100000 ${HOST_DATA}/${INSTANCE_NAME}
chown 100000:100000 ${HOST_DATA}/${INSTANCE_NAME}/home
pct set $INSTANCE_CT -mp0 ${HOST_DATA}/${INSTANCE_NAME}/home,mp=/home
pct start $INSTANCE_CT

pct exec $INSTANCE_CT -- useradd --create-home --shell /bin/bash --user-group --groups adm,sudo $USERNAME
echo "$USERNAME:$USERNAME" | pct exec $INSTANCE_CT -- chpasswd

pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt dist-upgrade -y

echo "Go to https://remotedesktop.google.com/headless to enable CRD."

