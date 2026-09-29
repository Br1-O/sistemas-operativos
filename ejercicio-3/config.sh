#!/usr/bin/env bash

DB_DRIVER_TYPE="TSV"
DRIVER_PATH_INVENTORY="./persistence/${DB_DRIVER_TYPE}/inventory/${DB_DRIVER_TYPE}_drivers_inventory.sh"
DRIVER_PATH_USERS="./persistence/${DB_DRIVER_TYPE}/users/${DB_DRIVER_TYPE}_drivers_users.sh"

PERSISTENCE_DRIVERS=("$DRIVER_PATH_INVENTORY" "$DRIVER_PATH_USERS")

for driver in "${PERSISTENCE_DRIVERS[@]}"; do
    if [[ -f "$driver" ]]; then
        source "$driver"
    else
        echo "No se encontraron los drivers de persistencia en la ruta $driver" >&2
        exit 1
    fi
done

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

load_modules "./use_cases" 
load_modules "./ui" 
load_modules "./utils" 