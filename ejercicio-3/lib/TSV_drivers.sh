#▀▀▀▀▀▀▀▀ persistence functions ▀▀▀▀▀▀▀▀#

load_inventory_into_array(){
    local -n invent_ref=$1

    if [[ ! -f datos_inventario.tsv ]]; then
        echo "No se encontró el archivo de inventario. Por favor compruebe que exista datos_inventario.tsv en su carpeta."
        return 1
    fi

    #read line per line with tabulation as the separator for 7 columns
    while IFS=$'\t' read -r id nombre categoria stock costo precio activo; do

        #check if the first value if empty or not valid, if so, ignore
        [[ -z "$id" || ! "$id" =~ ^[0-9]+$ ]] && continue

        #load values into the array via reference
        invent_ref["$id,id"]="$id"
        invent_ref["$id,nombre"]="$nombre"
        invent_ref["$id,categoria"]="$categoria"
        invent_ref["$id,stock"]="$stock"
        invent_ref["$id,costo"]="$costo"
        invent_ref["$id,precio"]="$precio"
        invent_ref["$id,activo"]="$activo"

    done < datos_inventario.tsv
}

save_product(){
    local -n invento_ref=$1
    local -i i=0

    > datos_inventario.tsv

    for ((i=0; i<MAX; i++)); do
        if [[ -n "${invento_ref[$i,id]}" ]]; then
            printf "%d\t%s\t%s\t%s\t%s\t%s\t%s\n" \
                "$i" \
                "${invento_ref[$i,nombre]}" \
                "${invento_ref[$i,categoria]}" \
                "${invento_ref[$i,stock]}" \
                "${invento_ref[$i,costo]}" \
                "${invento_ref[$i,precio]}"\
                "${invento_ref[$i,activo]}" >> datos_inventario.tsv
        fi
    done
}

save_user(){
    local username=$1
    local hashed_password="$(hash_password "$2")"

    printf "%s\t%s\n" \
        "${username}" \
        "${hashed_password}" >> datos_usuarios.tsv

    return 0
}

username_exists(){
    local entered_username="$1"

    if [[ ! -f datos_usuarios.tsv ]]; then
        echo "No se encontró el archivo de usuarios. Por favor compruebe que exista datos_usuarios.tsv en su carpeta."
        return 2
    fi

    #read line per line with tabulation as the separator for 3 columns
    while IFS=$'\t' read -r registered_username registered_password; do

        if [[ "${registered_username}" == "${entered_username}" ]] ; then
            return 0
        fi

    done < datos_usuarios.tsv

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

    done < datos_usuarios.tsv

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