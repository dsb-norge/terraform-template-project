#!/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

function _kill-files {
    local files file
    files=(
        "${SCRIPT_DIR}/step_1_scaffold.sh"
        "${SCRIPT_DIR}/step_2_bootstrap.sh"
        "${SCRIPT_DIR}/step_3_remove_init_scripts.sh"
        "${SCRIPT_DIR}/bootstrap.json"
    )
    echo "remove_init_scripts.sh: removing bootstrap files ..."
    for file in "${files[@]}"; do
        if [ -f "${file}" ]; then
            echo "remove_init_scripts.sh:   - ${file}"
            rm -f "${file}"
        fi
    done
    echo "remove_init_scripts.sh: done."
}

trap _kill-files EXIT
exit 0