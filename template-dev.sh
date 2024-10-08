#!/usr/bin/env bash

set -Eeu -o pipefail

# =======
# Imports
# =======

SCRIPT_PATH=${BASH_SOURCE[0]}
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
    SCRIPT_PATH=$(readlink "$SCRIPT_PATH")
    [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH=$SCRIPT_DIR/$SCRIPT_PATH
done
SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
SCRIPT_PATH="${SCRIPT_DIR}/$(basename "${SCRIPT_PATH}")"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/registry.sh"

set -x

# ============
# Local config
# ============

TEMPLATE_CT=$(registry_get_dependency template-dev)
INSTANCE_CT=$(registry_get_id template-dev)
INSTANCE_NAME=template-dev
INSTANCE_MEMORY=2048
INSTANCE_DISK=10G

GOLANG_VERSION=1.23.1

# ======
# Script
# ======

pct clone $TEMPLATE_CT $INSTANCE_CT --full 1
pct resize $INSTANCE_CT rootfs ${INSTANCE_DISK}
pct set $INSTANCE_CT \
    --hostname ${INSTANCE_NAME} \
    --memory   ${INSTANCE_MEMORY} \
    --net0     name=eth0,ip=dhcp,ip6=dhcp,bridge=vmbr0

host_passthrough_gpu $INSTANCE_CT

pct start $INSTANCE_CT

echo "Waiting for DNS to be available..."
sleep 5

# Dev software

pct_apt_add_key $INSTANCE_CT sublime-text https://download.sublimetext.com/sublimehq-pub.gpg 1EDDE2CDFC025D17F6DA9EC0ADAE6AD28A8F901A
pct_apt_add_repo $INSTANCE_CT sublime-text "https://download.sublimetext.com/ apt/stable/"
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
    ffmpeg \
    filezilla \
    flex \
    gdb \
    gimp \
    imagemagick \
    jpegoptim \
    libtool \
    meld \
    meson \
    mtools \
    nasm \
    nfs-common \
    ninja-build \
    ovmf \
    pandoc \
    pkg-config \
    python3-emoji \
    python3-pip \
    python3-pytest \
    ruby \
    ruby-dev \
    sublime-text \

pct_run_simple_bash_script $INSTANCE_CT "
export NOKOGIRI_USE_SYSTEM_LIBRARIES=1
gem install \
    asciidoctor \
    asciidoctor-epub3 \
    asciidoctor-pdf \
    epubcheck-ruby
"

pct_install_remote_deb $INSTANCE_CT "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"

pct_untar_remote_file $INSTANCE_CT "https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz" "/usr/local"
echo 'export PATH=$PATH:/usr/local/go/bin\n' | pct exec $INSTANCE_CT -- tee /etc/profile.d/golang.sh

pct_run_remote_script $INSTANCE_CT https://sh.rustup.rs -y

pct exec $INSTANCE_CT -- flatpak install -y https://flathub.org/repo/appstream/org.gimp.GIMP.flatpakref

# Delete dhcpv6 leases or else they'll never renew
pct_clear_dhcp_leases $INSTANCE_CT

# Turn this into a template
pct stop $INSTANCE_CT
pct template $INSTANCE_CT
