
TSV_USERS_PATH="shared/data/datos_usuarios.tsv"

init_users_storage() {
    if [[ ! -f "$TSV_USERS_PATH" ]]; then
        mkdir -p "$(dirname "$TSV_USERS_PATH")"
        echo -e "username\tpassword" > "$TSV_USERS_PATH"
    fi
}

username_exists(){
    local entered_username="$1"

    if [[ ! -f "${TSV_USERS_PATH}" ]]; then
        echo "No se encontró el archivo de usuarios. Por favor compruebe que exista $TSV_USERS_PATH en su carpeta."
        return 2
    fi

    #read line per line with tabulation as the separator for 3 columns
    while IFS=$'\t' read -r registered_username registered_password; do
    
        registered_username="${registered_username//$'\r'/}"

        if [[ "${registered_username}" == "${entered_username}" ]] ; then
            return 0
        fi

    done < "${TSV_USERS_PATH}"

    return 1
}

hash_password() {
    local password_value="$1"
    local -n _out_hash_ref=$2

    read -r _out_hash_ref _ < <(printf '%s' "${password_value}" | sha256sum)
}

save_user(){
    local username=$1
    local password="$2"
    local hashed_password=""

    hash_password "$password" hashed_password

    printf "%s\t%s\n" \
        "${username}" \
        "${hashed_password}" >> "${TSV_USERS_PATH}"

    return 0
}

find_hashed_password_by_username(){
    local entered_username="$1"
    local -n saved_password_ref=$2

    #read line per line with tabulation as the separator for 3 columns
    while IFS=$'\t' read -r registered_user registered_pass; do

        if [[ "${registered_user}" == "${entered_username}" ]] ; then
            saved_password_ref="${registered_pass//$'\r'/}"
            return 0
        fi

    done < "${TSV_USERS_PATH}"

    return 1
}

password_is_correct(){
    local entered_username="$1"
    local entered_password="$2"
    local saved_password=""
    local hashed_password=""

    find_hashed_password_by_username "${entered_username}" saved_password
    hash_password "$entered_password" hashed_password

    if [[ -z "${saved_password}" ]]; then
        return 1
    fi

    if [[ "${hashed_password}" == "${saved_password}" ]]; then
        return 0
    else
        return 1
    fi
}