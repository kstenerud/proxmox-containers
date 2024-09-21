#!/usr/bin/env bash

set -eux

INSTANCE_CT=100
INSTANCE_NAME=template-debian

# Debian Template

# pveam download local debian-12-standard_12.2-1_amd64.tar.zst

pct create $INSTANCE_CT local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst \
    --hostname ${INSTANCE_NAME} \
    --memory 2048 \
    --rootfs local-lvm:1 \
    --net0 name=eth0,hwaddr=12:4B:53:00:00:99,ip=dhcp,ip6=dhcp,bridge=vmbr0 \
    --ostype debian \
    --start 1 \
    --timezone host \
    --features nesting=1 \
    --unprivileged 1

# Force apt to use ipv4
echo 'Acquire::ForceIPv4 "true";' | pct exec $INSTANCE_CT -- tee /etc/apt/apt.conf.d/99force-ipv4
# echo 'precedence ::ffff:0:0/96  100' | pct exec $INSTANCE_CT -- tee -a /etc/gai.conf

# Bugfix: Stop container from holding up network trying to get a dhcpv6 lease
# echo 'net.ipv6.conf.all.disable_ipv6=1
# net.ipv6.conf.default.disable_ipv6=1
# net.ipv6.conf.lo.disable_ipv6=1
# ' | pct exec $INSTANCE_CT -- tee -a /etc/sysctl.conf

# Make sure DHCP client sends the correct identifier
echo "send dhcp-client-identifier = hardware;" | pct exec $INSTANCE_CT -- tee -a /etc/dhcp/dhclient.conf

pct stop $INSTANCE_CT
pct start $INSTANCE_CT

# Use a fast mirror
pct exec $INSTANCE_CT -- sed -i 's/deb.debian.org/ftp.uni-mainz.de/g' /etc/apt/sources.list

pct exec $INSTANCE_CT -- sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
pct exec $INSTANCE_CT -- locale-gen
pct exec $INSTANCE_CT -- update-locale LANG=en_US.UTF-8 LANGUAGE=en_US LC_ALL=en_US.UTF-8
pct exec $INSTANCE_CT -- sed -i 's/bookworm[^ ]* main contrib$/& non-free non-free-firmware/g' /etc/apt/sources.list
pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt dist-upgrade -y

pct stop $INSTANCE_CT
pct template $INSTANCE_CT

