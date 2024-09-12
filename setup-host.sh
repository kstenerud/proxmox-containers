#!/usr/bin/env bash

set -eux

# Switch to free mode
rm /etc/apt/sources.list.d/ceph.list
rm /etc/apt/sources.list.d/pve-enterprise.list
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" >/etc/apt/sources.list.d/pve-no-subscription.list

# Setup locale
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8 LANGUAGE=en_US LC_ALL=en_US.UTF-8

apt update
apt dist-upgrade -y
apt install ansible pip python3-proxmoxer htop strace git

# Setup user data area
lvcreate -V 1500GiB -T pve/data -n home_data
mke2fs -t ext4 -O ^has_journal /dev/pve/home_data
mkdir /home/data
echo "/dev/pve/home_data    /home/data   ext4    rw,discard,relatime   0    2" >>/etc/fstab
systemctl daemon-reload
mount -a

