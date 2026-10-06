#!/usr/bin/env bash

search_products_by_partial_name(){
    local -r product_name=$1
    local -n product_found_ref=$2
    local -n quantity_of_products_found=$3

    product_found_ref=()
    quantity_of_products_found=0

    shopt -s nocasematch

    for ((i=0; i<inventory_length; i++)); do
        if [[ -n "${inventario[$i,id]}" ]]; then
            local nombre_prod="${inventario[$i,nombre]}"

            if [[ "$nombre_prod" == *"${product_name}"* ]]; then

                local id=$quantity_of_products_found

                product_found_ref["$id,id"]="${inventario[$i,id]}"
                product_found_ref["$id,nombre"]="${inventario[$i,nombre]}"
                product_found_ref["$id,categoria"]="${inventario[$i,categoria]}"
                product_found_ref["$id,stock"]="${inventario[$i,stock]}"
                product_found_ref["$id,costo"]="${inventario[$i,costo]}"
                product_found_ref["$id,precio"]="${inventario[$i,precio]}"
                product_found_ref["$id,activo"]="${inventario[$i,activo]}"

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

    product_found_ref=()
    quantity_of_products_found=0

    shopt -s nocasematch

    for ((i=0; i<inventory_length; i++)); do
        if [[ -n "${inventario[$i,id]}" ]]; then
            local nombre_prod="${inventario[$i,nombre]}"

            if [[ "$nombre_prod" == "${product_name}" ]]; then

                local id=$quantity_of_products_found

                product_found_ref["$id,id"]="${inventario[$i,id]}"
                product_found_ref["$id,nombre"]="${inventario[$i,nombre]}"
                product_found_ref["$id,categoria"]="${inventario[$i,categoria]}"
                product_found_ref["$id,stock"]="${inventario[$i,stock]}"
                product_found_ref["$id,costo"]="${inventario[$i,costo]}"
                product_found_ref["$id,precio"]="${inventario[$i,precio]}"
                product_found_ref["$id,activo"]="${inventario[$i,activo]}"

                ((quantity_of_products_found++))
            fi
        fi
    done

    shopt -u nocasematch
}

create_product() {
    local -n prod_ref=$1
    local -i id=${prod_ref[id]}

    inventario[$id,id]="$id"
    inventario[$id,nombre]="${prod_ref[nombre]}"
    inventario[$id,categoria]="${prod_ref[categoria]}"
    inventario[$id,stock]="${prod_ref[stock]}"
    inventario[$id,costo]="${prod_ref[costo]}"
    inventario[$id,precio]="${prod_ref[precio]}"
    inventario[$id,activo]="${prod_ref[activo]}"

    printf "Producto %d (%s - categoria: %s) guardado correctamente con costo $%.2f. y con precio $%.2f.\n" \
        "$id" "${prod_ref[nombre]}" "${prod_ref[categoria]}" "${prod_ref[costo]}" "${prod_ref[precio]}"
}

delete_product() {
    local -i id=$1

    if [[ ${inventario[$id,activo]:-0} -eq 1 ]]; then
        inventario[$id,activo]=0
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

    if [[ -n "${inventario[$id,id]}" ]]; then

        inventario[$id,nombre]="${produc_ref[nombre]}"
        inventario[$id,categoria]="${produc_ref[categoria]}"
        inventario[$id,stock]="${produc_ref[stock]}"
        inventario[$id,costo]="${produc_ref[costo]}"
        inventario[$id,precio]="${produc_ref[precio]}"
        inventario[$id,activo]="${produc_ref[activo]}"

        printf "Producto %d (%s - categoria: %s) modificado correctamente con costo $%.2f. precio $%.2f.\n" \
        "$id" "${produc_ref[nombre]}" "${produc_ref[categoria]}" "${produc_ref[costo]}" "${produc_ref[precio]}"
        
    else
        printf "El producto no existe.\n"
        return 1
    fi

    return 0
}