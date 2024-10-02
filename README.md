Proxmox Container and Host Scripts
==================================

This wasn't intended for public release, but I'm doing so for people who have asked about it.

Watch your step and wear a hardhat!


## General layout

* `setup-XYZ`: Setup scripts for the host Proxmox systems. These are identical except for the reserved space. Run the script on a newly installed Proxmox.
* `common.sh`: Common functions
* `template-XYZ.sh`: Creates a template for a particular kind of container
* `instance-XYZ.sh`: Creates a running container instance from a template

## Hosts

* `thor`: A NUC host machine with 1tb SSD (I reserve 600gb for container persistent data)
* `nuc13`: A NUC host machine with 2tb SSD (I reserve 1500gb for container persistent data)

## Containers

* `dev`: My dev environment
* `tx`: My "transfer" environment. Basically a clean web browser and such that can be erased.
* `plex`: Plex media server. Connects to my NAS via the host, which connects over SAMBA (so that the container remains unprivileged).
