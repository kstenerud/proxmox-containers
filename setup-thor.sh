#!/usr/bin/env bash

set -Eeux -o pipefail

# ======
# Config
# ======

DATA_SIZE=600GiB

# ======
# Script
# ======

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
apt install -y software-properties-common
add-apt-repository -y non-free
apt install -y vainfo intel-media-va-driver-non-free lm-sensors
apt install -y ansible pip python3-proxmoxer htop strace git

# Setup user data area
lvcreate -V ${DATA_SIZE} -T pve/data -n home_data
mke2fs -t ext4 -O ^has_journal /dev/pve/home_data
mkdir /home/data
echo "/dev/pve/home_data    /home/data   ext4    rw,discard,relatime   0    2" >>/etc/fstab
mkdir -p /mnt/containers/media
echo "//media/media  /mnt/containers/media cifs  uid=100000,gid=100000,ro,guest,x-systemd.automount 0 0" >>/etc/fstab
mkdir -p /mnt/containers/files
echo "//files/files  /mnt/containers/files cifs  uid=100000,gid=100000,ro,credentials=/etc/samba/credentials,x-systemd.automount 0 0" >>/etc/fstab
systemctl daemon-reload
mount -a

