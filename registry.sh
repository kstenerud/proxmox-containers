#!/usr/bin/env bash

set -Eeu -o pipefail

#
# The registry maps template and instance names to Proxmox container IDs, and keeps track of dependencies.
#

declare -A REGISTRY_NAME_TO_ID
declare -A REGISTRY_NAME_TO_DEPENDENCY
declare -A REGISTRY_ID_TO_NAME

# Usage: register_container <name> <proxmox container id> <depends on template>
# Where "-" in the dependency field means no dependency (script will find its own os template)
register_container() {
	local name="$1"
	local id="$2"
	local dependency="$3"
	if [[ "$dependency" == "-" ]]; then
		dependency=0
	else
		dependency="$(registry_get_id $dependency)"
	fi

	REGISTRY_NAME_TO_ID["$name"]="$id"
	REGISTRY_NAME_TO_DEPENDENCY["$name"]="$dependency"
	REGISTRY_ID_TO_NAME["$id"]="$name"
}

# ===
# API
# ===

registry_get_id() {
	local name="$1"
	local entry="${REGISTRY_NAME_TO_ID["${name}"]:-}"
	if [[ -z "${entry}" ]]; then
		>&2 echo "Hypervisor registry: Name [$name] not found"
		return 1
	fi
	echo "$entry"
}

registry_get_dependency() {
	local name="$1"
	local entry="${REGISTRY_NAME_TO_DEPENDENCY["${name}"]:-}"
	if [[ -z "${entry}" ]]; then
		>&2 echo "Hypervisor registry: Name [$name] not found"
		return 1
	fi
	echo "$entry"
}

registry_get_name() {
	local id="$1"
	local entry="${REGISTRY_ID_TO_NAME["${id}"]:-}"
	if [[ -z "${entry}" ]]; then
		>&2 echo "Hypervisor registry: ID [$id] not found"
		return 1
	fi
	echo "$entry"
}

# ========
# Registry
# ========

# NOTE: Names MUST match the script base names or else the rebuild script won't work!

# Top-level templates. These pull from the official Proxmox OS templates and thus have no dependencies.
# I put them into separate 100 ranges based on the top-level template for clarity's sake.
register_container template-debian      100 -
register_container template-ubuntu      200 -

# Specialized templates.
register_container template-debian-mate 101 template-debian
register_container template-tx          102 template-debian-mate
register_container template-dev         103 template-debian-mate
register_container template-plex        201 template-ubuntu

# Instances. Numbered higher so they're easier to identify.
register_container instance-tx        10000 template-tx
register_container instance-dev       10001 template-dev
register_container instance-plex      10002 template-plex
