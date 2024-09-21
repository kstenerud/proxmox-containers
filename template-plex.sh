#!/usr/bin/env bash

set -eux

SRC_CT=200
TEMPLATE_CT=201

pct clone $SRC_CT $TEMPLATE_CT --full 1
pct resize $TEMPLATE_CT rootfs 2G
pct set $TEMPLATE_CT \
    --hostname template \
    --memory 2048 \
    --net0 name=eth0,hwaddr=12:4B:53:00:00:99,ip=dhcp,ip6=dhcp,bridge=vmbr0

# Passthrough GPU
echo 'lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file
lxc.hook.pre-start: sh -c "chown 0:108 /dev/dri/renderD128"
' >> /etc/pve/lxc/${TEMPLATE_CT}.conf

pct start $TEMPLATE_CT

pct exec $TEMPLATE_CT -- apt update
pct exec $TEMPLATE_CT -- apt dist-upgrade -y
pct exec $TEMPLATE_CT -- apt install -y samba curl

curl https://downloads.plex.tv/plex-keys/PlexSign.key | pct exec $TEMPLATE_CT -- sudo apt-key add -
echo deb https://downloads.plex.tv/repo/deb public main | pct exec $TEMPLATE_CT -- sudo tee /etc/apt/sources.list.d/plexmediaserver.list
pct exec $TEMPLATE_CT -- apt update
pct exec $TEMPLATE_CT -- apt install -y plexmediaserver

pct stop $TEMPLATE_CT
pct template $TEMPLATE_CT

