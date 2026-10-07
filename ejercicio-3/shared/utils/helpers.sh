
clear_screen() {
    # 1. Intenta usar el comando ejecutable nativo del sistema
    if command -v clear >/dev/null 2>&1; then
        clear
    # 2. Respaldo para Windows nativo (CMD / PowerShell dentro de Git Bash)
    elif command -v cls >/dev/null 2>&1; then
        cls
    # 3. Respaldo universal por código de escape ANSI (funciona en casi cualquier emulador de terminal)
    else
        printf "\033[c\033[2J\033[H"
    fi
}

get_value_with_cancel_action_option() {
    local original_message="$1"
    local -n out_value_ref=$2
    local user_input=""

    read -r -p "${original_message}("q" para cancelar) " user_input

    if [[ "${user_input,,}" == "q" ]]; then
        clear_screen
        return 1
    fi

    out_value_ref="$user_input"
    return 0
}

update_array_length_variable_by_ref(){
    local -n inventory_ref=$1
    local -n inventory_length_ref=$2
    local -i new_inventory_length=0

    local count=0
    for key in "${!inventory_ref[@]}"; do
        [[ "$key" == *",id" ]] && ((count++))
    done

    inventory_length_ref=$count
}