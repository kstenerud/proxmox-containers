#!/usr/bin/env bash

set -eux

# ============
# Local config
# ============

TEMPLATE_CT=102
INSTANCE_CT=10000
INSTANCE_NAME=tx
INSTANCE_ADDRESS=22
INSTANCE_MEMORY=32768
INSTANCE_USERNAME=karl

# ===========
# Host config
# ===========

HOST_DATA=/home/data
HOST_BASE_UID=100000
HOST_BASE_GID=100000

# ======
# Script
# ======

pct clone $TEMPLATE_CT $INSTANCE_CT --full 1
pct set $INSTANCE_CT \
    --onboot   1 \
    --hostname ${INSTANCE_NAME} \
    --memory   ${INSTANCE_MEMORY} \
    --net0     name=eth0,hwaddr=12:4B:53:00:00:${INSTANCE_ADDRESS},ip=dhcp,ip6=dhcp,bridge=vmbr0

# Home dir
mkdir -p /home/data/${INSTANCE_NAME}/home
chown ${HOST_BASE_UID}:${HOST_BASE_GID} ${HOST_DATA}/${INSTANCE_NAME}
chown ${HOST_BASE_UID}:${HOST_BASE_GID} ${HOST_DATA}/${INSTANCE_NAME}/home
pct set $INSTANCE_CT -mp0 ${HOST_DATA}/${INSTANCE_NAME}/home,mp=/home

pct start $INSTANCE_CT

# User
pct exec $INSTANCE_CT -- useradd --create-home --shell /bin/bash --user-group --groups adm,sudo ${INSTANCE_USERNAME}
echo "${INSTANCE_USERNAME}:${INSTANCE_USERNAME}" | pct exec $INSTANCE_CT -- chpasswd

pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt dist-upgrade -y

set +x
echo "==========================================================="
echo "Go to https://remotedesktop.google.com/headless to enable CRD."
echo "==========================================================="

