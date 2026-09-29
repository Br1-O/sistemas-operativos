#!/usr/bin/env bash

TSV_INVENTORY_PATH="data/datos_inventario.tsv"

load_inventory_into_array(){
    local -n invent_ref=$1

    if [[ ! -f "${TSV_INVENTORY_PATH}" ]]; then
        echo "No se encontró el archivo de inventario. Por favor compruebe que exista $TSV_INVENTORY_PATH"
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

    done < "${TSV_INVENTORY_PATH}"
}

save_product(){
    local -n invento_ref=$1
    local -i i=0

    > "${TSV_INVENTORY_PATH}"

    for ((i=0; i<inventory_length; i++)); do
        if [[ -n "${invento_ref[$i,id]}" ]]; then
            printf "%d\t%s\t%s\t%s\t%s\t%s\t%s\n" \
                "$i" \
                "${invento_ref[$i,nombre]}" \
                "${invento_ref[$i,categoria]}" \
                "${invento_ref[$i,stock]}" \
                "${invento_ref[$i,costo]}" \
                "${invento_ref[$i,precio]}"\
                "${invento_ref[$i,activo]}" >> "${TSV_INVENTORY_PATH}"
        fi
    done
}