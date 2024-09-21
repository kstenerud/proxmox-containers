#!/usr/bin/env bash

set -eux

INSTANCE_CT=200

# Ubuntu 24.04 Template

# pveam download local ubuntu-24.04-standard_24.04-2_amd64.tar.zst

pct create $INSTANCE_CT local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst \
    --hostname template \
    --memory 2048 \
    --rootfs local-lvm:1 \
    --net0 name=eth0,hwaddr=12:4B:53:00:00:99,ip=dhcp,ip6=dhcp,bridge=vmbr0 \
    --ostype ubuntu \
    --start 1 \
    --timezone host \
    --features nesting=1 \
    --unprivileged 1

# Use a fast mirror
pct exec $INSTANCE_CT -- sed -i 's/archive.ubuntu.com/ftp.uni-stuttgart.de/g' /etc/apt/sources.list

pct exec $INSTANCE_CT -- sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
pct exec $INSTANCE_CT -- locale-gen
pct exec $INSTANCE_CT -- update-locale LANG=en_US.UTF-8 LANGUAGE=en_US LC_ALL=en_US.UTF-8

pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt install -y software-properties-common
pct exec $INSTANCE_CT -- apt dist-upgrade -y

pct stop $INSTANCE_CT
pct template $INSTANCE_CT

