#!/usr/bin/env bash

set -eux

# ============
# Local config
# ============

TEMPLATE_CT=101
INSTANCE_CT=102
INSTANCE_NAME=template-tx
INSTANCE_MEMORY=2048
INSTANCE_DISK=10G

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
    --net0     name=eth0,ip=dhcp,ip6=dhcp,bridge=vmbr0

passthrough_gpu $INSTANCE_CT

pct start $INSTANCE_CT

echo "Waiting for DNS to be available..."
sleep 5

# Software

apt_add_key $INSTANCE_CT sublime-text https://download.sublimetext.com/sublimehq-pub.gpg 1EDDE2CDFC025D17F6DA9EC0ADAE6AD28A8F901A
apt_add_repo $INSTANCE_CT sublime-text "https://download.sublimetext.com/ apt/stable/"
pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt dist-upgrade -y
pct exec $INSTANCE_CT -- apt install -y transmission-remote-gtk amule-utils-gui mpv sublime-text

pct exec $INSTANCE_CT -- flatpak install -y https://flathub.org/repo/appstream/org.gimp.GIMP.flatpakref

# Delete dhcpv6 leases or else they'll never renew
echo "rm /var/lib/dhcp/dhclient*" | pct exec $INSTANCE_CT -- sh

# Turn this into a template
pct stop $INSTANCE_CT
pct template $INSTANCE_CT
