#!/usr/bin/env bash

TSV_USERS_PATH="shared/data/datos_usuarios.tsv"

init_users_storage() {
    if [[ ! -f "$TSV_USERS_PATH" ]]; then
        mkdir -p "$(dirname "$TSV_USERS_PATH")"
        echo -e "username\tpassword" > "$TSV_USERS_PATH"
    fi
}

save_user(){
    local username=$1
    local hashed_password="$(hash_password "$2")"

    printf "%s\t%s\n" \
        "${username}" \
        "${hashed_password}" >> "${TSV_USERS_PATH}"

    return 0
}

username_exists(){
    local entered_username="$1"

    if [[ ! -f "${TSV_USERS_PATH}" ]]; then
        echo "No se encontró el archivo de usuarios. Por favor compruebe que exista $TSV_USERS_PATH en su carpeta."
        return 2
    fi

    #read line per line with tabulation as the separator for 3 columns
    while IFS=$'\t' read -r registered_username registered_password; do

        if [[ "${registered_username}" == "${entered_username}" ]] ; then
            return 0
        fi

    done < "${TSV_USERS_PATH}"

    return 1
}

hash_password(){
    local password="$1"

    printf "%s" "${password}" | sha256sum | awk '{print $1}' 

    return 0
}

find_hashed_password_by_username(){
    local entered_username="$1"

    #read line per line with tabulation as the separator for 3 columns
    while IFS=$'\t' read -r registered_user registered_pass; do

        if [[ "${registered_user}" == "${entered_username}" ]] ; then
            printf "%s" "${registered_pass}"
            return 0
        fi

    done < "${TSV_USERS_PATH}"

    return 1
}

password_is_correct(){
    local entered_username="$1"
    local entered_password="$(hash_password "$2")" 
    local saved_password="$( find_hashed_password_by_username "${entered_username}" )"

    if [[ -z "${saved_password}" ]]; then
        return 1
    fi

    if [[ "${entered_password}" == "${saved_password}" ]]; then
        return 0
    else
        return 1
    fi
}