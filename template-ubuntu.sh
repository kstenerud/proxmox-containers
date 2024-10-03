#!/usr/bin/env bash
#
# Ubuntu 24.04 Template
#

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

TEMPLATE_IMAGE="ubuntu-24.04-standard_24.04-2_amd64.tar.zst"

INSTANCE_CT=$(registry_get_id template-ubuntu)
INSTANCE_NAME=template-ubuntu
INSTANCE_MEMORY=2048

# ======
# Script
# ======

pveam download local ${TEMPLATE_IMAGE} || true

pct create $INSTANCE_CT local:vztmpl/${TEMPLATE_IMAGE} \
    --hostname ${INSTANCE_NAME} \
    --memory   ${INSTANCE_MEMORY} \
    --rootfs   local-lvm:1 \
    --net0     name=eth0,ip=dhcp,ip6=dhcp,bridge=vmbr0 \
    --ostype   ubuntu \
    --start    1 \
    --timezone host \
    --features nesting=1 \
    --unprivileged 1

# Use a fast mirror
pct exec $INSTANCE_CT -- sed -i 's/archive.ubuntu.com/ftp.uni-stuttgart.de/g' /etc/apt/sources.list

# Set up locale
pct exec $INSTANCE_CT -- sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
pct exec $INSTANCE_CT -- locale-gen
pct exec $INSTANCE_CT -- update-locale LANG=en_US.UTF-8 LANGUAGE=en_US LC_ALL=en_US.UTF-8

# Bring everything up to date
pct exec $INSTANCE_CT -- apt clean
pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt dist-upgrade -y
pct exec $INSTANCE_CT -- apt install -y software-properties-common curl

# Turn this into a template
pct stop $INSTANCE_CT
pct template $INSTANCE_CT
