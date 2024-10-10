#!/usr/bin/env bash

set -Eeux -o pipefail

# ============
# Local config
# ============

INSTANCE_CT=1001

# ======
# Script
# ======

qm shutdown $INSTANCE_CT

qm template $INSTANCE_CT
