#!/usr/bin/env bash

set -eux

SCRIPT_PATH=${BASH_SOURCE[0]}
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
    SCRIPT_PATH=$(readlink "$SCRIPT_PATH")
    [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH=$SCRIPT_DIR/$SCRIPT_PATH
done
SCRIPT_DIR=$( cd -P "$( dirname "$SCRIPT_PATH" )" >/dev/null 2>&1 && pwd )
SCRIPT_PATH="${SCRIPT_DIR}/$(basename "${SCRIPT_PATH}")"
source "$SCRIPT_DIR/common.sh"

pct_destroy() {
	pct stop $1 || true
	pct destroy $1 || true
}

run_builder() {
	bash "${SCRIPT_DIR}/$1"
}

pct_destroy 100
pct_destroy 101
pct_destroy 102
pct_destroy 103
pct_destroy 200
pct_destroy 201

run_builder template-ubuntu.sh
run_builder template-plex.sh
run_builder template-debian.sh
run_builder template-debian-mate.sh
run_builder template-dev.sh
run_builder template-tx.sh
