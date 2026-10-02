#!/usr/bin/env bash

#▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ User Functions ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀#

define CURRENT_USER=""

set_current_user() {
    CURRENT_USER="$1"
}

create_user(){
    local username=""
    local password=""

    clear_screen
    
    while true; do
        read -rp $'Ingresa tu nombre de usuario deseado:\n' username

        if [[ -z "${username}" ]]; then
            printf "No puedes ingresar un nombre vacío.\n\n"
        elif username_exists "${username}"; then
            printf "¡El usuario ya existe! Por favor, ingresa otro.\n\n"
        else
            break
        fi
    done

    read -rsp $'Ingresa una contraseña para tu usuario: \n' password
    echo ""

    while [[ -z "${password}" ]]; do
        read -rsp $'No puedes ingresar una contraseña vacia.\nIngresa una contraseña para tu usuario:\n' password
        echo ""
    done

    if save_user "${username}" "${password}" ; then
        printf "¡El usuario se ha creado exitosamente!"
        return 0
    else
        printf "¡Ha ocurrido un error! Por favor, chequea que el archivo users.tsv se encuentra presente en tu carpeta"
        return 1
    fi
}

auth_user(){
    local -i tries=0
    local username=""
    local password=""

    local hashed_password=""

    clear_screen

    while (( tries<5 )); do
        read -rp $'Ingresa tu usuario: \n' username

        if [[ -z "${username}" ]]; then
            printf $'No puedes ingresar un nombre vacio.\n'
            continue
        fi

        if ! username_exists "${username}"; then
            (( tries++ ))
            printf 'No se ha encontrado registro para ese usuario. Por favor, chequee que sea correcto. Intentos restantes %d\n' "$((5 - tries))"
        else
            break
        fi
    done        

    if (( tries>=5 )); then
        printf "¡Intentos fallidos maximos alcanzados!"
        exit 1
    fi

    tries=0

    while (( tries<3 )); do
        read -rsp $'Ingresa tu contraseña: \n' password
        echo ""

        if [[ -z "${password}" ]]; then
            printf $'No puedes ingresar una contraseña vacia.\n'
            continue
        fi

        if password_is_correct "${username}" "${password}" ; then
            set_current_user "${username}"
            printf "Login exitoso. ¡Bienvenido, $username! \n"
            return 0
        fi

        (( tries++ ))
        printf "Contraseña incorrecta. (intentos restantes "$(( 3 - tries ))")"
    done

    printf "¡Intentos fallidos maximos alcanzados!"
    exit 1
}
