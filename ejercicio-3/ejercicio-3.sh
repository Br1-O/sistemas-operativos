#!/usr/bin/env bash


CONFIG_IMPORTS_PATH="./config.sh"

if [[ -f "${CONFIG_IMPORTS_PATH}" ]]; then
    source "${CONFIG_IMPORTS_PATH}"
else
    echo "No se encontraron las configuraciones de la aplicación."
    exit 1
fi


declare -A inventario=()
declare -r -i MAX=50
declare -i inventory_length=0

cleanup() {
    commit_inventory_journal inventario
    exit 0
}

main() {

    # Ctrl+C (SIGINT), terminal closing (SIGHUP), termination (SIGTERM)
    trap cleanup SIGINT SIGHUP SIGTERM

    welcome_message

    if ! get_option_from_user_and_execute_login_or_register; then
        return 1
    fi
  
    load_inventory_into_array inventario

    update_array_length_variable_by_ref inventario inventory_length

    get_option_from_user_and_execute_inventory_action inventario inventory_length

    return 0
}

main