#!/usr/bin/env bash

set -eux

# ============
# Local config
# ============

TEMPLATE_CT=101
INSTANCE_CT=103
INSTANCE_NAME=template-dev
INSTANCE_ADDRESS=99
INSTANCE_MEMORY=2048
INSTANCE_DISK=10G

GOLANG_VERSION=1.23.1

# ======
# Script
# ======

SCRIPT_PATH=${BASH_SOURCE[0]}
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
    SCRIPT_PATH=$(readlink "$SCRIPT_PATH")
    [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH=$SCRIPT_DIR/$SCRIPT_PATH
done
SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
SCRIPT_PATH="${SCRIPT_DIR}/$(basename "${SCRIPT_PATH}")"
source "$SCRIPT_DIR/common.sh"

pct clone $TEMPLATE_CT $INSTANCE_CT --full 1
pct resize $INSTANCE_CT rootfs ${INSTANCE_DISK}
pct set $INSTANCE_CT \
    --hostname ${INSTANCE_NAME} \
    --memory   ${INSTANCE_MEMORY} \
    --net0     name=eth0,hwaddr=12:4B:53:00:00:${INSTANCE_ADDRESS},ip=dhcp,ip6=dhcp,bridge=vmbr0

passthrough_gpu $INSTANCE_CT

pct start $INSTANCE_CT

# Dev software

apt_add_key2 $INSTANCE_CT sublime-text https://download.sublimetext.com/sublimehq-pub.gpg 1EDDE2CDFC025D17F6DA9EC0ADAE6AD28A8F901A
apt_add_repo2 $INSTANCE_CT sublime-text "https://download.sublimetext.com/ apt/stable/"
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
	sublime-text \

install_remote_deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
install_remote_deb "http://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb"

untar_remote_file "https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz" "/usr/local"
echo 'export PATH=$PATH:/usr/local/go/bin\n' | pct exec $INSTANCE_CT -- tee /etc/profile.d/golang.sh

run_remote_script https://sh.rustup.rs -y

pct exec $INSTANCE_CT -- flatpak install -y https://flathub.org/repo/appstream/org.gimp.GIMP.flatpakref

# Delete dhcpv6 leases or else they'll never renew
echo "rm /var/lib/dhcp/dhclient*" | pct exec $INSTANCE_CT -- sh

# Turn this into a template
pct stop $INSTANCE_CT
pct template $INSTANCE_CT
