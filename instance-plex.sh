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

TEMPLATE_CT=$(registry_get_dependency instance-plex)
INSTANCE_CT=$(registry_get_id instance-plex)
INSTANCE_NAME=plex
INSTANCE_ADDRESS=12
INSTANCE_MEMORY=2048

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

# Mount the media dir
pct set $INSTANCE_CT -mp1 /mnt/containers/media,mp=/mnt/media
pct set $INSTANCE_CT -mp2 /mnt/containers/files/p,mp=/mnt/p

# Get the UID and GID of the plex user
pct start $INSTANCE_CT
PLEX_UID=$(pct exec $INSTANCE_CT -- id -u plex)
PLEX_GID=$(pct exec $INSTANCE_CT -- id -g plex)
PLEX_HOST_UID=$(($HOST_BASE_UID+$PLEX_UID))
PLEX_HOST_GID=$(($HOST_BASE_GID+$PLEX_GID))
pct stop $INSTANCE_CT

# Mount the Plex config dir
mkdir -p /home/data/${INSTANCE_NAME}/var-lib-plexmediaserver
chown -R ${PLEX_HOST_UID}:${PLEX_HOST_GID} ${HOST_DATA}/${INSTANCE_NAME}
chown -R ${PLEX_HOST_UID}:${PLEX_HOST_GID} ${HOST_DATA}/${INSTANCE_NAME}/var-lib-plexmediaserver
pct set $INSTANCE_CT -mp0 ${HOST_DATA}/${INSTANCE_NAME}/var-lib-plexmediaserver,mp=/var/lib/plexmediaserver

pct start $INSTANCE_CT
pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt dist-upgrade -y

IP_ADDR=$(pct exec $INSTANCE_CT -- hostname -I | xargs)
set +x
echo "==========================================================="
echo "FOR FIRST TIME SETUP (no existing config):"
echo
echo "Go to https://www.plex.tv/claim/"
echo "pct exec $INSTANCE_CT -- curl -X POST 'http://127.0.0.1:32400/myplex/claim?token=PASTE_TOKEN_HERE'"
echo "Then, go to ${IP_ADDR}:32400"
echo "==========================================================="

