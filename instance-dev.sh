#!/usr/bin/env bash

set -Eeu -o pipefail

# =======
# Imports
# =======

SCRIPT_PATH=${BASH_SOURCE[0]}
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
    SCRIPT_PATH=$(readlink "$SCRIPT_PATH")
    [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH=$SCRIPT_DIR/$SCRIPT_PATH
done
SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
SCRIPT_PATH="${SCRIPT_DIR}/$(basename "${SCRIPT_PATH}")"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/registry.sh"

set -x

# ============
# Local config
# ============

TEMPLATE_CT=$(registry_get_dependency instance-dev)
INSTANCE_CT=$(registry_get_id instance-dev)
INSTANCE_NAME=dev
INSTANCE_ADDRESS=21
INSTANCE_MEMORY=16384
INSTANCE_USERNAME=karl

# ===========
# Host config
# ===========

HOST_DATA=/home/data

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

# Files mount
pct set $INSTANCE_CT -mp1 /mnt/containers/files,mp=/mnt/files

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

