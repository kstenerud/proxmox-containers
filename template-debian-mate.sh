#!/usr/bin/env bash

set -eux

TEMPLATE_CT=100
INSTANCE_CT=101
INSTANCE_NAME=template-debian-mate

# Debian Mate Desktop Template

pct clone $TEMPLATE_CT $INSTANCE_CT --full 1
pct resize $INSTANCE_CT rootfs 4G
pct set $INSTANCE_CT \
    --hostname ${INSTANCE_NAME} \
    --memory 2048 \
    --net0 name=eth0,hwaddr=12:4B:53:00:00:99,ip=dhcp,ip6=dhcp,bridge=vmbr0
pct start $INSTANCE_CT

pct exec $INSTANCE_CT -- wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O /etc/apt/keyrings/packages.mozilla.org.asc
pct exec $INSTANCE_CT -- gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else {print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"; exit 1}}'
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | pct exec $INSTANCE_CT -- tee /etc/apt/sources.list.d/mozilla.list
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | pct exec $INSTANCE_CT -- tee /etc/apt/preferences.d/mozilla

pct exec $INSTANCE_CT -- apt update
pct exec $INSTANCE_CT -- apt dist-upgrade -y
pct exec $INSTANCE_CT -- apt install sudo git gnupg locales net-tools nmap telnet tree tzdata unzip
pct exec $INSTANCE_CT -- apt install mate-desktop-environment mate-desktop-environment-extras mate-themes mate-tweak avahi-daemon webp libavif-gdk-pixbuf unrar rar p7zip-rar
pct exec $INSTANCE_CT -- apt install flatpak gnome-software-plugin-flatpak
pct exec $INSTANCE_CT -- apt install vlc firefox

pct exec $INSTANCE_CT -- flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

pct stop $INSTANCE_CT
pct template $INSTANCE_CT

