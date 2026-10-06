#!/usr/bin/env bash

PERSISTENCE_ENGINE="${PERSISTENCE_ENGINE:-sqlite}"

load_persistence() {
    local engine="${1:-$PERSISTENCE_ENGINE}"

    if [[ "$PERSISTENCE_ENGINE" == "sqlite" ]]; then
        source "$(dirname "${BASH_SOURCE[0]}")/inventory/persistence/sqlite/inventory_sqlite.sh"
        source "$(dirname "${BASH_SOURCE[0]}")/user/persistence/sqlite/users_sqlite.sh"
    else
        source "$(dirname "${BASH_SOURCE[0]}")/inventory/persistence/tsv/inventory_tsv.sh"
        source "$(dirname "${BASH_SOURCE[0]}")/user/persistence/tsv/users_tsv.sh"
    fi
}

load_persistence "$PERSISTENCE_ENGINE"

load_modules(){
    local target_dir="$1"

    for module in "${target_dir}"/*.sh; do

        if [[ -f "$module" ]]; then
            source "$module"
        else
            echo "No se encontró el módulo $module" >&2
        fi

    done
}

load_modules "./inventory/use_cases" 
load_modules "./inventory/ui" 
load_modules "./shared/utils" 
load_modules "./user/use_cases" 
load_modules "./user/ui" 