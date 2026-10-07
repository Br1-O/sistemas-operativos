#!/usr/bin/env bash

declare -A inventory_global_array=()
declare -i inventory_length=0
declare SERVER_PID_VALUE=0

CONFIG_IMPORTS_PATH="./config.sh"
source "${CONFIG_IMPORTS_PATH}" "${1,,:-sqlite}"

cleanup() {
    commit_inventory_journal inventory_global_array
    stop_local_http_server SERVER_PID
    exit 0
}

main() {

    # Ctrl+C (SIGINT), terminal closing (SIGHUP), termination (SIGTERM)
    trap cleanup SIGINT SIGHUP SIGTERM

    trap 'stty sane 2>/dev/null' EXIT INT TERM

    welcome_message

    if ! get_option_from_user_and_execute_login_or_register; then
        return 1
    fi
  
    load_inventory_into_array inventory_global_array

    update_array_length_variable_by_ref inventory_global_array inventory_length

    get_option_from_user_and_execute_inventory_action inventory_global_array inventory_length SERVER_PID_VALUE

    return 0
}

main