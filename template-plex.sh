#!/usr/bin/env bash

set -eux

TEMPLATE_CT=200
INSTANCE_CT=201
INSTANCE_NAME=template-ubuntu

pct clone $TEMPLATE_CT $INSTANCE_CT --full 1
pct resize $INSTANCE_CT rootfs 2G
pct set $INSTANCE_CT \
    --hostname ${INSTANCE_NAME} \
    --memory 2048 \
    --net0 name=eth0,hwaddr=12:4B:53:00:00:99,ip=dhcp,ip6=dhcp,bridge=vmbr0

# Passthrough GPU
echo 'lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file
lxc.hook.pre-start: sh -c "chown 0:108 /dev/dri/renderD128"
' >> /etc/pve/lxc/${INSTANCE_CT}.conf

pct start $INSTANCE_CT

pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt dist-upgrade -y
pct exec $INSTANCE_CT -- apt install -y samba curl

curl https://downloads.plex.tv/plex-keys/PlexSign.key | pct exec $INSTANCE_CT -- sudo apt-key add -
echo deb https://downloads.plex.tv/repo/deb public main | pct exec $INSTANCE_CT -- sudo tee /etc/apt/sources.list.d/plexmediaserver.list
pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt install -y plexmediaserver

pct stop $INSTANCE_CT
pct template $INSTANCE_CT

