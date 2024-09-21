#!/usr/bin/env bash

set -eux

TEMPLATE_CT=101
INSTANCE_CT=103
INSTANCE_NAME=template-dev

GOLANG_VERSION=1.23.1

install_remote_deb() {
	local url="$1"
	pct exec $INSTANCE_CT -- wget -qO /tmp/installer.deb "$url"
	pct exec $INSTANCE_CT -- bash -c "export DEBIAN_FRONTEND=noninteractive; apt install -y /tmp/installer.deb"
	pct exec $INSTANCE_CT -- rm /tmp/installer.deb
}

untar_remote_file() {
	local url="$1"
	local path="$2"
	pct exec $INSTANCE_CT -- wget -qO /tmp/archive.tgz "$url"
	pct exec $INSTANCE_CT -- tar -C "$path" -xf /tmp/archive.tgz
	pct exec $INSTANCE_CT -- rm /tmp/archive.tgz
}

pct clone $TEMPLATE_CT $INSTANCE_CT --full 1
pct set $INSTANCE_CT \
    --hostname ${INSTANCE_NAME} \
    --memory 2048 \
    --net0 name=eth0,hwaddr=12:4B:53:00:00:99,ip=dhcp,ip6=dhcp,bridge=vmbr0
pct resize $INSTANCE_CT rootfs 10G
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
pct exec $INSTANCE_CT -- apt install -y \
	antlr4 \
	autoconf \
	autopkgtest \
	bison \
	build-essential \
	cmake \
	cpu-checker \
	curl \
	debconf-utils \
	devscripts \
	filezilla \
	flex \
	gdb \
	gimp \
	libtool \
	meld \
	meson \
	mtools \
	nasm \
	nfs-common \
	ninja-build \
	ovmf \
	pkg-config \
	python3-pip \
	python3-pytest \
	samba \
	sublime-text \

install_remote_deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
install_remote_deb "http://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb"

untar_remote_file "https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz" "/usr/local"
echo 'export PATH=$PATH:/usr/local/go/bin\n' | pct exec $INSTANCE_CT -- tee /etc/profile.d/golang.sh

pct exec $INSTANCE_CT -- wget -O /tmp/script.sh https://sh.rustup.rs
pct exec $INSTANCE_CT -- chmod a+x /tmp/script.sh
pct exec $INSTANCE_CT -- /tmp/script.sh -y
pct exec $INSTANCE_CT -- rm /tmp/script.sh

# Delete dhcpv6 leases or else they'll never renew
echo "rm /var/lib/dhcp/dhclient*" | pct exec $INSTANCE_CT -- sh

pct stop $INSTANCE_CT
pct template $INSTANCE_CT

