#!/usr/bin/env bash

#
# MS Key Management Server
#
# From your enterprise windows command prompt:
#
#   slmgr /upk
#   slmgr /ipk [Enterprise Product Key]
#   slmgr /skms [kms server hostname or ip]
#   slmgr /ato
#

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

TEMPLATE_CT=$(registry_get_dependency template-kms)
INSTANCE_CT=$(registry_get_id template-kms)
INSTANCE_NAME=template-kms
INSTANCE_DISK=2G


# ======
# Script
# ======

pct clone $TEMPLATE_CT $INSTANCE_CT --full 1
pct resize $INSTANCE_CT rootfs ${INSTANCE_DISK}
pct set $INSTANCE_CT \
    --hostname ${INSTANCE_NAME} \
    --net0     name=eth0,ip=dhcp,ip6=dhcp,bridge=vmbr0

pct start $INSTANCE_CT

echo "Waiting for DNS to be available..."
sleep 5

pct exec $INSTANCE_CT -- apt install -y git dpkg-dev debhelper net-tools

# Workaround: Kick the DNS server so it doesn't error out looking up github
pct exec $INSTANCE_CT -- ping -c 2 github.com
pct_clone_git_repo $INSTANCE_CT https://github.com/Wind4/vlmcsd.git - /tmp/vlmcsd
pct_install_deb_from_src $INSTANCE_CT /tmp/vlmcsd
pct exec $INSTANCE_CT -- rm -rf /tmp/vlmcsd

# Delete dhcpv6 leases or else they'll never renew
pct_clear_dhcp_leases $INSTANCE_CT

# Turn this into a template
pct stop $INSTANCE_CT
pct template $INSTANCE_CT
