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

TEMPLATE_CT=$(registry_get_dependency template-libretranslate)
INSTANCE_CT=$(registry_get_id template-libretranslate)
INSTANCE_NAME=template-libretranslate
INSTANCE_DISK=20G

VERSION_LIBRETRANSLATE=v1.6.1
VERSION_BABEL=2.12.1
VERSION_TORCH=2.0.1

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

pct exec $INSTANCE_CT -- apt install -y git

# Workaround: Kick the DNS server so it doesn't error out looking up github
pct exec $INSTANCE_CT -- ping -c 2 github.com
pct_clone_git_repo $INSTANCE_CT https://github.com/LibreTranslate/LibreTranslate.git $VERSION_LIBRETRANSLATE /app

# Required software
pct exec $INSTANCE_CT -- apt install -y pkg-config gcc g++ python3-pip python3-venv

# User/group to run under
pct exec $INSTANCE_CT -- addgroup --system --gid 1032 libretranslate
pct exec $INSTANCE_CT -- adduser --system --uid 1032 libretranslate
pct exec $INSTANCE_CT -- mkdir -p /home/libretranslate/.local
pct exec $INSTANCE_CT -- chown -R libretranslate:libretranslate /home/libretranslate
pct exec $INSTANCE_CT -- chown -R libretranslate:libretranslate /app

# Setup virtualenv
pct_run_simple_bash_script $INSTANCE_CT "
cd /app
python3 -mvenv venv
./venv/bin/pip install --no-cache-dir --upgrade pip
./venv/bin/pip install Babel==$VERSION_BABEL
./venv/bin/python scripts/compile_locales.py
./venv/bin/pip install torch==$VERSION_TORCH --extra-index-url https://download.pytorch.org/whl/cpu
./venv/bin/pip install \"numpy<2\"
./venv/bin/pip install .
./venv/bin/python scripts/install_models.py
"
pct exec $INSTANCE_CT -- chown -R libretranslate:libretranslate /app

# Setup systemd
echo "[Unit]
Description=LibreTranslate
After=network.target

[Service]
WorkingDirectory=/app
ExecStart=/app/venv/bin/libretranslate --host \"*\"
Type=exec
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
RequiredBy=network.target
" | pct exec $INSTANCE_CT -- tee /etc/systemd/system/libretranslate.service
pct exec $INSTANCE_CT -- systemctl daemon-reload
pct exec $INSTANCE_CT -- systemctl enable libretranslate.service

# Delete dhcpv6 leases or else they'll never renew
pct_clear_dhcp_leases $INSTANCE_CT

# Turn this into a template
pct stop $INSTANCE_CT
pct template $INSTANCE_CT
