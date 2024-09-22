#!/usr/bin/env bash

set -eux

# SCRIPT_PATH=${BASH_SOURCE[0]}
# while [ -L "$SCRIPT_PATH" ]; do
#     SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
#     SCRIPT_PATH=$(readlink "$SCRIPT_PATH")
#     [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH=$SCRIPT_DIR/$SCRIPT_PATH
# done
# SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
# SCRIPT_PATH="${SCRIPT_DIR}/$(basename "${SCRIPT_PATH}")"
# source "$SCRIPT_DIR/common.sh"


install_remote_deb() {
    local url="$1"
    pct exec $INSTANCE_CT -- wget -qO /tmp/installer.deb "$url"
    pct exec $INSTANCE_CT -- bash -c "export DEBIAN_FRONTEND=noninteractive; apt install -y /tmp/installer.deb"
    pct exec $INSTANCE_CT -- rm /tmp/installer.deb
}

run_remote_script() {
    local url="$1"
    shift
    pct exec $INSTANCE_CT -- wget -qO /tmp/remote_script.sh "$url"
    pct exec $INSTANCE_CT -- bash /tmp/remote_script.sh "$@"
    pct exec $INSTANCE_CT -- rm /tmp/remote_script.sh
}

untar_remote_file() {
    local url="$1"
    local path="$2"
    pct exec $INSTANCE_CT -- wget -qO /tmp/archive.tgz "$url"
    pct exec $INSTANCE_CT -- tar -C "$path" -xf /tmp/archive.tgz
    pct exec $INSTANCE_CT -- rm /tmp/archive.tgz
}

passthrough_gpu() {
    local instance_id="$1"
    echo 'lxc.cgroup2.devices.allow: c 226:0 rwm
    lxc.cgroup2.devices.allow: c 226:128 rwm
    lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file
    lxc.hook.pre-start: sh -c "chown 0:108 /dev/dri/renderD128"
    ' >> /etc/pve/lxc/${instance_id}.conf
}

apt_add_key() {
    local instance_id="$1"
    local url="$2"
    wget -qO - "$url" | pct exec $instance_id -- apt-key add -
}

apt_add_repo() {
    local instance_id="$1"
    local name="$2"
    local repo="$3"
    echo "$repo" | pct exec $instance_id -- tee /etc/apt/sources.list.d/${name}.list
}

clear_dhcp_leases() {
    local instance_id="$1"
    echo "rm /var/lib/dhcp/dhclient*" | pct exec $instance_id -- sh
}

apt_add_key2() {
    # https://askubuntu.com/questions/1286545/what-commands-exactly-should-replace-the-deprecated-apt-key
    local instance_id="$1"
    local key_name="$2"
    local url="$3"
    local expected_signature="$4"

    local temp_key=/tmp/key.asc
    local temp_keyring=/tmp/temp-keyring.gpg
    rm -f "$temp_key"
    rm -f "$temp_keyring"

    wget -q "$url" -O "$temp_key"
    local signature=$( gpg -n -q  --no-default-keyring --keyring "$temp_keyring" --import --import-options import-show "$temp_key" | awk '/pub/{getline; gsub(/^ +| +$/,""); print $0;}' )
    if [ "$signature" != "$expected_signature" ]; then
        echo "Error: Expected signature [$expected_signature] but got [$signature]"
        return 1
    fi

    gpg --no-default-keyring --keyring "$temp_keyring" --export --output "/etc/apt/keyrings/${key_name}.gpg"
    rm -f "$temp_key"
    rm -f "$temp_keyring"
}

apt_add_repo2() {
    local instance_id="$1"
    local name="$2"
    local repo="$3"
    echo "deb [signed-by=/etc/apt/keyrings/${name}.gpg] ${repo}" | pct exec $instance_id -- tee /etc/apt/sources.list.d/${name}.list
}
