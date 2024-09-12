#!/usr/bin/env bash

set -eux

MATE_CT=101
TEMPLATE_CT=102

pct clone $MATE_CT $TEMPLATE_CT --full 1
pct set $TEMPLATE_CT \
    --hostname template \
    --memory 2048 \
    --net0 name=eth0,hwaddr=12:4B:53:00:00:99,ip=dhcp,ip6=dhcp,bridge=vmbr0
pct start $TEMPLATE_CT

wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | pct exec $TEMPLATE_CT -- apt-key add -
echo "deb https://download.sublimetext.com/ apt/stable/" | pct exec $TEMPLATE_CT -- tee /etc/apt/sources.list.d/sublime-text.list
pct exec $TEMPLATE_CT -- apt update
pct exec $TEMPLATE_CT -- apt dist-upgrade -y
pct exec $TEMPLATE_CT -- apt install -y nmap samba transmission-remote-gtk amule-utils-gui gimp mpv sublime-text

# https://remotedesktop.google.com/headless
pct exec $TEMPLATE_CT -- wget -qO /tmp/crd.deb http://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
pct exec $TEMPLATE_CT -- apt install -y /tmp/crd.deb
pct exec $TEMPLATE_CT -- rm /tmp/crd.deb
pct stop $TEMPLATE_CT
pct template $TEMPLATE_CT

