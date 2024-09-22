#!/usr/bin/env bash

set -eux

# ============
# Local config
# ============

TEMPLATE_CT=200
INSTANCE_CT=201
INSTANCE_NAME=template-plex
INSTANCE_ADDRESS=99
INSTANCE_MEMORY=2048

# ======
# Script
# ======

SCRIPT_PATH=${BASH_SOURCE[0]}
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
    SCRIPT_PATH=$(readlink "$SCRIPT_PATH")
    [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH=$SCRIPT_DIR/$SCRIPT_PATH
done
SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
SCRIPT_PATH="${SCRIPT_DIR}/$(basename "${SCRIPT_PATH}")"
source "$SCRIPT_DIR/common.sh"

pct clone $TEMPLATE_CT $INSTANCE_CT --full 1
pct resize $INSTANCE_CT rootfs 2G
pct set $INSTANCE_CT \
    --hostname ${INSTANCE_NAME} \
    --memory   ${INSTANCE_MEMORY} \
    --net0     name=eth0,hwaddr=12:4B:53:00:00:${INSTANCE_ADDRESS},ip=dhcp,ip6=dhcp,bridge=vmbr0

passthrough_gpu $INSTANCE_CT

pct start $INSTANCE_CT

# Install precursors
pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt dist-upgrade -y
pct exec $INSTANCE_CT -- apt install -y samba

# Install Plex
apt_add_key $INSTANCE_CT plexmediaserver https://downloads.plex.tv/plex-keys/PlexSign.key CD665CBA0E2F88B7373F7CB997203C7B3ADCA79D
apt_add_repo $INSTANCE_CT plexmediaserver "https://downloads.plex.tv/repo/deb public main"
pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt install -y plexmediaserver

# Turn this into a template
pct stop $INSTANCE_CT
pct template $INSTANCE_CT
