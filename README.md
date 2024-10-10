Proxmox Container and Host Scripts
==================================

This wasn't intended for public release, but I'm doing so for people who have asked about it.

Watch your step and wear a hardhat!


## General Philosophy

* The host is modified as little as possible from the stock install.
* The GUI is for MONITORING ONLY. Once you start changing things from the GUI side, you lose reproducibility.
* All data that I want to persist across container destruction goes into the host's filesystem under `/home/data/my-container-name`. There's an `lvcreate` command in the setup script that reserves space for it.
* The instance scripts set specific MAC addresses so that my main DHCP server will assign them their proper IP addresses as if they were first class machines on the network.
* Remote desktop access is done via Chrome Remote Desktop.
* I pass through the host's GPU in many cases.
* NAS mounted directories are passed through via the host, which connects over SAMBA with automount. This allows me to keep the containers unprivileged.

## Architecture

Script naming and component responsibilities.

### Main Scripts

* `setup-XYZ`: Setup scripts for the host Proxmox systems. These are identical except for the reserved space. Run the script on a newly installed Proxmox.
* `template-XYZ.sh`: Creates a template for a particular kind of container
* `instance-XYZ.sh`: Creates a running container instance from a template

### Support Scripts

* `rebuild-all-templates.sh`: Destroys and rebuilds all templates (NOT instances) that are in the registry
* [`support` dir](support)

### Includes

* `common.sh`: Common functions
* `registry.sh`: Registry of all containers we're interested in


## Topography

You'll want to change these for your own topography.

### Hosts

* `thor`: My host machine with 1tb SSD (I reserve 600gb for container persistent data)
* `nuc13`: My host machine with 2tb SSD (I reserve 1500gb for container persistent data)

### Containers

* `dev`: My dev virtual desktop environment
* `tx`: My "transfer" virtual desktop environment. Basically a clean web browser and such that can be erased.
* `emergency`: My emergency virtual desktop environment (in case the main host goes down)
* `plex`: Plex media server. Connects to my NAS via the host, which connects over SAMBA (so that the container remains unprivileged).
* `kms`: Key management server for windows
* `libretranslate`: AI translator

### Virtual Machines

* `win10`: Windows 10
