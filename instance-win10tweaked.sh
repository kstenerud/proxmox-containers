#!/usr/bin/env bash

set -Eeux -o pipefail

# ============
# Local config
# ============

TEMPLATE_CT=1001
INSTANCE_CT=11000
INSTANCE_NAME=win10
INSTANCE_ADDRESS=60
INSTANCE_MEMORY=8192

# ======
# Script
# ======

qm clone $TEMPLATE_CT $INSTANCE_CT
qm set $INSTANCE_CT \
    --name     ${INSTANCE_NAME} \
    --memory   ${INSTANCE_MEMORY} \
    --net0     macaddr=12:4B:53:00:00:${INSTANCE_ADDRESS},bridge=vmbr0,model=virtio

qm start $INSTANCE_CT
