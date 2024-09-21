#!/usr/bin/env bash

set -eux

TEMPLATE_CT=101
INSTANCE_CT=102
INSTANCE_NAME=template-tx

pct clone $TEMPLATE_CT $INSTANCE_CT --full 1
pct resize $INSTANCE_CT rootfs 10G
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

wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | pct exec $INSTANCE_CT -- apt-key add -
echo "deb https://download.sublimetext.com/ apt/stable/" | pct exec $INSTANCE_CT -- tee /etc/apt/sources.list.d/sublime-text.list
pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt dist-upgrade -y
pct exec $INSTANCE_CT -- apt install -y nmap samba transmission-remote-gtk amule-utils-gui mpv sublime-text

pct exec $INSTANCE_CT -- flatpak install -y https://flathub.org/repo/appstream/org.gimp.GIMP.flatpakref

# https://remotedesktop.google.com/headless
pct exec $INSTANCE_CT -- wget -qO /tmp/crd.deb http://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
pct exec $INSTANCE_CT -- apt install -y /tmp/crd.deb
pct exec $INSTANCE_CT -- rm /tmp/crd.deb
pct stop $INSTANCE_CT
pct template $INSTANCE_CT

