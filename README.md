Proxmox Container and Host Scripts
==================================

This wasn't intended for public release, but I'm doing so for people who have asked about it.

Watch your step and wear a hardhat!


## General layout

* `setup-XYZ`: Setup scripts for the host Proxmox systems. These are kept simple.
* `common.sh`: Common functions
* `template-XYZ.sh`: Creates a template for a particular kind of software
* `instance-XYZ.sh`: Creates a running instance of a particular template
* `dev`: My dev environment
* `tx`: My "transfer" environment. Basically a clean web browser and such that can be erased.
