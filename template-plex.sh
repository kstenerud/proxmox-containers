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

pct clone $TEMPLATE_CT $INSTANCE_CT --full 1
pct resize $INSTANCE_CT rootfs 2G
pct set $INSTANCE_CT \
    --hostname ${INSTANCE_NAME} \
    --memory   ${INSTANCE_MEMORY} \
    --net0     name=eth0,hwaddr=12:4B:53:00:00:${INSTANCE_ADDRESS},ip=dhcp,ip6=dhcp,bridge=vmbr0

# Passthrough GPU
echo 'lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file
lxc.hook.pre-start: sh -c "chown 0:108 /dev/dri/renderD128"
' >> /etc/pve/lxc/${INSTANCE_CT}.conf

pct start $INSTANCE_CT

# Install precursors
pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt dist-upgrade -y
pct exec $INSTANCE_CT -- apt install -y samba

# Install Plex
curl https://downloads.plex.tv/plex-keys/PlexSign.key | pct exec $INSTANCE_CT -- sudo apt-key add -
echo deb https://downloads.plex.tv/repo/deb public main | pct exec $INSTANCE_CT -- sudo tee /etc/apt/sources.list.d/plexmediaserver.list
pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt install -y plexmediaserver

# Turn this into a template
pct stop $INSTANCE_CT
pct template $INSTANCE_CT
