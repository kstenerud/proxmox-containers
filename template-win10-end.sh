#!/usr/bin/env bash

set -Eeux -o pipefail

# ============
# Local config
# ============

INSTANCE_CT=1000

# ======
# Script
# ======

qm shutdown $INSTANCE_CT

qm unlink $INSTANCE_CT --idlist ide0,ide2

qm template $INSTANCE_CT
