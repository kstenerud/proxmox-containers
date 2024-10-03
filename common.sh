#!/usr/bin/env bash

set -Eeu -o pipefail

#
# Common functions used in the other scripts.
#
# Be sure to use a robust sourcing mechanism, such as:
#
# SCRIPT_PATH=${BASH_SOURCE[0]}
# while [ -L "$SCRIPT_PATH" ]; do
#     SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
#     SCRIPT_PATH=$(readlink "$SCRIPT_PATH")
#     [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH=$SCRIPT_DIR/$SCRIPT_PATH
# done
# SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
# SCRIPT_PATH="${SCRIPT_DIR}/$(basename "${SCRIPT_PATH}")"
# source "$SCRIPT_DIR/common.sh"
#

# When mapping UIDs and GIDs for file ownership, the host side adds 100000
HOST_BASE_UID=100000
HOST_BASE_GID=100000

host_passthrough_gpu() {
    local instance_id="$1"
    echo 'lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file
lxc.hook.pre-start: sh -c "chown 0:108 /dev/dri/renderD128"
' >> /etc/pve/lxc/${instance_id}.conf
}

pct_install_remote_deb() {
    local instance_id="$1"
    local url="$2"
    pct exec $instance_id -- wget -qO /tmp/installer.deb "$url"
    pct exec $instance_id -- bash -c "export DEBIAN_FRONTEND=noninteractive; apt install -y /tmp/installer.deb"
    pct exec $instance_id -- rm /tmp/installer.deb
}

pct_run_remote_script() {
    local instance_id="$1"
    local url="$2"
    shift
    shift
    pct exec $instance_id -- wget -qO /tmp/remote_script.sh "$url"
    pct exec $instance_id -- bash /tmp/remote_script.sh "$@"
    pct exec $instance_id -- rm /tmp/remote_script.sh
}

pct_untar_remote_file() {
    local instance_id="$1"
    local url="$2"
    local path="$3"
    pct exec $instance_id -- wget -qO /tmp/archive.tgz "$url"
    pct exec $instance_id -- tar -C "$path" -xf /tmp/archive.tgz
    pct exec $instance_id -- rm /tmp/archive.tgz
}

pct_clear_dhcp_leases() {
    local instance_id="$1"
    echo "rm /var/lib/dhcp/dhclient*" | pct exec $instance_id -- sh
}

pct_apt_add_key() {
    # https://askubuntu.com/questions/1286545/what-commands-exactly-should-replace-the-deprecated-apt-key
    local instance_id="$1"
    local key_name="$2"
    local url="$3"
    local expected_signature="$4"

    local temp_key=/tmp/key.asc
    local temp_keyring=/tmp/temp-keyring.gpg
    rm -f "$temp_key"
    rm -f "$temp_keyring"

    pct exec $instance_id -- wget "$url" -O "$temp_key"
    local signature=$( pct exec $instance_id -- gpg -q --no-default-keyring --keyring "$temp_keyring" --import --import-options import-show "$temp_key" | awk '/pub/{getline; gsub(/^ +| +$/,""); print $0;}' )
    if [ "$signature" != "$expected_signature" ]; then
        echo "Error: Expected signature [$expected_signature] but got [$signature]"
        return 1
    fi

    pct exec $instance_id -- gpg --no-default-keyring --keyring "$temp_keyring" --export --output "/etc/apt/keyrings/${key_name}.gpg"
    pct exec $instance_id -- rm -f "$temp_key"
    pct exec $instance_id -- rm -f "$temp_keyring"
}

pct_apt_add_repo() {
    local instance_id="$1"
    local name="$2"
    local repo="$3"
    echo "deb [signed-by=/etc/apt/keyrings/${name}.gpg] ${repo}" | pct exec $instance_id -- tee /etc/apt/sources.list.d/${name}.list
}
