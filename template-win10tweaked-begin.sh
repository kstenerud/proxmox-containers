#!/usr/bin/env bash

set -Eeux -o pipefail

# ============
# Local config
# ============

TEMPLATE_CT=1000
INSTANCE_CT=1001
INSTANCE_NAME=template-win10tweaked
INSTANCE_MEMORY=4096
INSTANCE_CORES=2
INSTANCE_SOCKETS=2

# ======
# Script
# ======

qm clone $TEMPLATE_CT $INSTANCE_CT \
    --name $INSTANCE_NAME \

qm set $INSTANCE_CT \
    --memory $INSTANCE_MEMORY \
    --cores $INSTANCE_CORES \
    --sockets $INSTANCE_SOCKETS \

qm start $INSTANCE_CT

set +x
echo "
=================================================
* Install tweaks:
  - From admin powershell: irm https://christitus.com/win | iex

* Run template-win10tweaked-end.sh
=================================================
"
