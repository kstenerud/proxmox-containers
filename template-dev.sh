#!/usr/bin/env bash

set -eux

MATE_CT=101
TEMPLATE_CT=103

GOLANG_VERSION=1.23.1

install_remote_deb() {
	local url="$1"
	pct exec $TEMPLATE_CT -- wget -qO /tmp/installer.deb "$url"
	pct exec $TEMPLATE_CT -- bash -c "export DEBIAN_FRONTEND=noninteractive; apt install -y /tmp/installer.deb"
	pct exec $TEMPLATE_CT -- rm /tmp/installer.deb
}

untar_remote_file() {
	local url="$1"
	local path="$2"
	pct exec $TEMPLATE_CT -- wget -qO /tmp/archive.tgz "$url"
	pct exec $TEMPLATE_CT -- tar -C "$path" -xf /tmp/archive.tgz
	pct exec $TEMPLATE_CT -- rm /tmp/archive.tgz
}

pct clone $MATE_CT $TEMPLATE_CT --full 1
pct set $TEMPLATE_CT \
    --hostname template \
    --memory 2048 \
    --net0 name=eth0,hwaddr=12:4B:53:00:00:99,ip=dhcp,ip6=dhcp,bridge=vmbr0
pct resize $TEMPLATE_CT rootfs 10G
pct start $TEMPLATE_CT

wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | pct exec $TEMPLATE_CT -- apt-key add -
echo "deb https://download.sublimetext.com/ apt/stable/" | pct exec $TEMPLATE_CT -- tee /etc/apt/sources.list.d/sublime-text.list
pct exec $TEMPLATE_CT -- apt update
pct exec $TEMPLATE_CT -- apt dist-upgrade -y
pct exec $TEMPLATE_CT -- apt install -y \
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
echo 'export PATH=$PATH:/usr/local/go/bin\n' | pct exec $TEMPLATE_CT -- tee /etc/profile.d/golang.sh

pct exec $TEMPLATE_CT -- wget -O /tmp/script.sh https://sh.rustup.rs
pct exec $TEMPLATE_CT -- chmod a+x /tmp/script.sh
pct exec $TEMPLATE_CT -- /tmp/script.sh -y
pct exec $TEMPLATE_CT -- rm /tmp/script.sh

pct stop $TEMPLATE_CT
pct template $TEMPLATE_CT

