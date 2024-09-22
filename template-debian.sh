#!/usr/bin/env bash
#
# Debian 12 Template
#

set -eux

# ============
# Local config
# ============

TEMPLATE_IMAGE=debian-12-standard_12.7-1_amd64.tar.zst

INSTANCE_CT=100
INSTANCE_NAME=template-debian
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
    --ostype   debian \
    --start    1 \
    --timezone host \
    --features nesting=1 \
    --unprivileged 1

# Apt: Assume yes, download from hosts simultaneously, retry 10 times
echo 'APT::Get::Assume-Yes "true";

Acquire {
  Queue-Mode "host";
  Retries "10";
};
' | pct exec $INSTANCE_CT -- tee /etc/apt/apt.conf.d/99custom-config

# Force apt to use ipv4
# echo 'Acquire::ForceIPv4 "true";' | pct exec $INSTANCE_CT -- tee /etc/apt/apt.conf.d/99force-ipv4
# Lower ipv6 precedence
# echo 'precedence ::ffff:0:0/96  100' | pct exec $INSTANCE_CT -- tee -a /etc/gai.conf

# Disable ipv6 so that it doesn't hold up the network trying to get a dhcpv6 lease
# echo 'net.ipv6.conf.all.disable_ipv6=1
# net.ipv6.conf.default.disable_ipv6=1
# net.ipv6.conf.lo.disable_ipv6=1
# ' | pct exec $INSTANCE_CT -- tee -a /etc/sysctl.conf

# Make sure DHCP client sends the hardware identifier
# echo "send dhcp-client-identifier = hardware;" | pct exec $INSTANCE_CT -- tee -a /etc/dhcp/dhclient.conf

# Restart after messing with the network settings
# pct stop $INSTANCE_CT
# pct start $INSTANCE_CT

# Use a fast mirror
pct exec $INSTANCE_CT -- sed -i 's/deb.debian.org/ftp2.de.debian.org/g' /etc/apt/sources.list

# Extra mirror
# echo "deb http://ftp.uni-mainz.de/debian bookworm main contrib non-free non-free-firmware
# deb http://ftp.uni-mainz.de/debian bookworm-updates main contrib non-free non-free-firmware" | pct exec $INSTANCE_CT -- tee /etc/apt/sources.list.d/ftp.uni-mainz.de.list

# Set up locale
pct exec $INSTANCE_CT -- sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
pct exec $INSTANCE_CT -- locale-gen
pct exec $INSTANCE_CT -- update-locale LANG=en_US.UTF-8 LANGUAGE=en_US LC_ALL=en_US.UTF-8

# Enable non-free repos
pct exec $INSTANCE_CT -- sed -i 's/bookworm[^ ]* main contrib$/& non-free non-free-firmware/g' /etc/apt/sources.list

# Bring everything up to date
pct exec $INSTANCE_CT -- apt clean
pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt dist-upgrade -y
pct exec $INSTANCE_CT -- apt install -y software-properties-common curl

# Turn this into a template
pct stop $INSTANCE_CT
pct template $INSTANCE_CT
