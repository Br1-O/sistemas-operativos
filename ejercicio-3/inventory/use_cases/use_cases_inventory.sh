
search_products_by_partial_name(){
    local -r product_name=$1
    local -n product_found_ref=$2
    local -n quantity_of_products_found=$3
    local -i invent_length="$4"
    local -n inventory_array=$5

    product_found_ref=()
    quantity_of_products_found=0

    shopt -s nocasematch

    for ((i=0; i<invent_length; i++)); do
        if [[ -n "${inventory_array[$i,id]}" ]]; then
            local nombre_prod="${inventory_array[$i,nombre]}"

            if [[ "$nombre_prod" == *"${product_name}"* ]]; then

                local id=$quantity_of_products_found

                product_found_ref["$id,id"]="${inventory_array[$i,id]}"
                product_found_ref["$id,nombre"]="${inventory_array[$i,nombre]}"
                product_found_ref["$id,categoria"]="${inventory_array[$i,categoria]}"
                product_found_ref["$id,stock"]="${inventory_array[$i,stock]}"
                product_found_ref["$id,costo"]="${inventory_array[$i,costo]}"
                product_found_ref["$id,precio"]="${inventory_array[$i,precio]}"
                product_found_ref["$id,activo"]="${inventory_array[$i,activo]}"

                ((quantity_of_products_found++))
            fi
        fi
    done

    shopt -u nocasematch
}

search_products_by_name(){
    local -r product_name=$1
    local -n product_found_ref=$2
    local -n quantity_of_products_found=$3
    local -i invent_length="$4"
    local -n inventory_array=$5

    product_found_ref=()
    quantity_of_products_found=0

    shopt -s nocasematch

    for ((i=0; i<invent_length; i++)); do
        if [[ -n "${inventory_array[$i,id]}" ]]; then
            local nombre_prod="${inventory_array[$i,nombre]}"

            if [[ "$nombre_prod" == "${product_name}" ]]; then

                local id=$quantity_of_products_found

                product_found_ref["$id,id"]="${inventory_array[$i,id]}"
                product_found_ref["$id,nombre"]="${inventory_array[$i,nombre]}"
                product_found_ref["$id,categoria"]="${inventory_array[$i,categoria]}"
                product_found_ref["$id,stock"]="${inventory_array[$i,stock]}"
                product_found_ref["$id,costo"]="${inventory_array[$i,costo]}"
                product_found_ref["$id,precio"]="${inventory_array[$i,precio]}"
                product_found_ref["$id,activo"]="${inventory_array[$i,activo]}"

                ((quantity_of_products_found++))
            fi
        fi
    done

    shopt -u nocasematch
}

create_product() {
    local -n prod_ref=$1
    local -i id=${prod_ref[id]}
    local -n inventory_array=$2

    inventory_array[$id,id]="$id"
    inventory_array[$id,nombre]="${prod_ref[nombre]}"
    inventory_array[$id,categoria]="${prod_ref[categoria]}"
    inventory_array[$id,stock]="${prod_ref[stock]}"
    inventory_array[$id,costo]="${prod_ref[costo]}"
    inventory_array[$id,precio]="${prod_ref[precio]}"
    inventory_array[$id,activo]="${prod_ref[activo]}"

    printf "Producto %d (%s - categoria: %s) guardado correctamente con costo $%.2f. y con precio $%.2f.\n" \
        "$id" "${prod_ref[nombre]}" "${prod_ref[categoria]}" "${prod_ref[costo]}" "${prod_ref[precio]}"
}

delete_product() {
    local -i id=$1
    local -n inventory_array=$2

    if [[ ${inventory_array[$id,activo]:-0} -eq 1 ]]; then
        inventory_array[$id,activo]=0
        printf "Producto %d dado de baja.\n" "$id"
    else
        printf "El producto ya fue dado de baja.\n"
        return 1
    fi

    return 0
}

update_product() {
    local -n produc_ref=$1
    local -i id=${produc_ref[id]}
    local -n inventory_array=$2

    if [[ -n "${inventory_array[$id,id]}" ]]; then

        inventory_array[$id,nombre]="${produc_ref[nombre]}"
        inventory_array[$id,categoria]="${produc_ref[categoria]}"
        inventory_array[$id,stock]="${produc_ref[stock]}"
        inventory_array[$id,costo]="${produc_ref[costo]}"
        inventory_array[$id,precio]="${produc_ref[precio]}"
        inventory_array[$id,activo]="${produc_ref[activo]}"

        printf "Producto %d (%s - categoria: %s) modificado correctamente con costo $%.2f. precio $%.2f.\n" \
        "$id" "${produc_ref[nombre]}" "${produc_ref[categoria]}" "${produc_ref[costo]}" "${produc_ref[precio]}"
        
    else
        printf "El producto no existe.\n"
        return 1
    fi

    return 0
}