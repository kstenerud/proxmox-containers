#!/usr/bin/env bash

set -Eeu -o pipefail

#
# Rebuilds all templates (NOT instances) in the registry.
#
# This allows you to verify / update your templates without shutting down your instances.
#

# =======
# Imports
# =======

SCRIPT_PATH=${BASH_SOURCE[0]}
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
    SCRIPT_PATH=$(readlink "$SCRIPT_PATH")
    [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH=$SCRIPT_DIR/$SCRIPT_PATH
done
SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
SCRIPT_PATH="${SCRIPT_DIR}/$(basename "${SCRIPT_PATH}")"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/registry.sh"

# ======
# Script
# ======

set +x

declare -A REBUILT_TEMPLATES

rebuild_template() {
    local name="$1"
    local entry="${REBUILT_TEMPLATES[${name}]:-}"
    if [[ ! -z "${entry}" ]]; then
        return
    fi
    REBUILT_TEMPLATES["$name"]=1

    if [[ $name != template* ]]; then
        return
    fi

    local dependency=$(registry_get_dependency $name)
    if (( $dependency > 0 )); then
        rebuild_template $(registry_get_name $dependency)
    fi

    local id=$(registry_get_id $name)
    echo "Rebuilding $id: $name"

    local build_script="${SCRIPT_DIR}/${name}.sh"
    if [ ! -f "$build_script" ]; then
        >&2 echo "Build script [$build_script] not found. Is it named in accordance with [${SCRIPT_DIR}/registry.sh]?"
        return 1
    fi

    pct stop $id || true
    pct destroy $id || true
    bash "$build_script"
}


for name in ${!REGISTRY_NAME_TO_ID[@]}; do
    rebuild_template "$name"
done
