#!/usr/bin/env bash
#
# Ubuntu 24.04 Template
#

set -eux

# ============
# Local config
# ============

TEMPLATE=ubuntu-24.04-standard_24.04-2_amd64.tar.zst

INSTANCE_CT=200
INSTANCE_NAME=template-ubuntu
INSTANCE_ADDRESS=99
INSTANCE_MEMORY=2048

# ======
# Script
# ======

pveam download local ${TEMPLATE_IMAGE} || true

pct create $INSTANCE_CT local:vztmpl/${TEMPLATE_IMAGE} \
    --hostname ${INSTANCE_NAME} \
    --memory   ${INSTANCE_MEMORY} \
    --rootfs   local-lvm:1 \
    --net0     name=eth0,hwaddr=12:4B:53:00:00:${INSTANCE_ADDRESS},ip=dhcp,ip6=dhcp,bridge=vmbr0 \
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
