#!/usr/bin/env bash

set -Eeux -o pipefail

# ============
# Local config
# ============

INSTANCE_CT=1000
INSTANCE_NAME=template-win10
INSTANCE_MEMORY=4096
INSTANCE_CORES=2
INSTANCE_SOCKETS=2

# ======
# Script
# ======

qm create $INSTANCE_CT \
    --name $INSTANCE_NAME \
    --memory $INSTANCE_MEMORY \
    --cores $INSTANCE_CORES \
    --sockets $INSTANCE_SOCKETS \
    --cdrom local:iso/Win10_22H2_English_x64v1.iso \
    --ide0 local:iso/virtio-win-0.1.262.iso,media=cdrom \
    --audio0 device=ich9-intel-hda,driver=none \
    --ostype win10 \
    --cpu host \
    --net0 model=virtio,bridge=vmbr0 \
    --bootdisk scsi0 \
    --scsi0 local-lvm:30,iothread=1,cache=writeback,discard=on \
    --scsihw virtio-scsi-single \
    --boot "order=scsi0;ide2;ide0;net0" \
    --agent 1

qm start $INSTANCE_CT

set +x
echo "
=================================================
* Select 'Custom Install'

* Load drivers:
  - SCSI:   vioscsi\w10\amd64
  - Memory: Balloon\w10\amd64

* Do offline install

* After base OS installed, run from virtio CD:
  - virtio-win-gt-x64.msi
  - virtio-win-guest-tools.msi
  - guest-agent/qemu-ga-x86_64.msi

* Install all system updates

* Customize OS

* Disk cleanup

* Run template-win10-end.sh
=================================================
"
