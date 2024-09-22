#!/usr/bin/env bash
#
# Debian Mate Desktop Template
#

set -eux

# ============
# Local config
# ============

TEMPLATE_CT=100
INSTANCE_CT=101
INSTANCE_NAME=template-debian-mate
INSTANCE_MEMORY=2048
INSTANCE_DISK=4G

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
pct start $INSTANCE_CT

echo "Waiting for DNS to be available..."
sleep 5

# Firefox repo
apt_add_key $INSTANCE_CT mozilla https://packages.mozilla.org/apt/repo-signing-key.gpg 35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3
apt_add_repo $INSTANCE_CT mozilla "https://packages.mozilla.org/apt mozilla main"
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | pct exec $INSTANCE_CT -- tee /etc/apt/preferences.d/mozilla

# Install desktop environment
pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt dist-upgrade -y
pct exec $INSTANCE_CT -- apt install sudo git gnupg locales net-tools nmap telnet tree tzdata unzip samba
pct exec $INSTANCE_CT -- apt install mate-desktop-environment mate-desktop-environment-extras mate-themes mate-tweak avahi-daemon webp libavif-gdk-pixbuf unrar rar p7zip-rar
pct exec $INSTANCE_CT -- apt install flatpak gnome-software-plugin-flatpak
pct exec $INSTANCE_CT -- apt install vlc firefox

pct exec $INSTANCE_CT -- flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Turn this into a template
pct stop $INSTANCE_CT
pct template $INSTANCE_CT

