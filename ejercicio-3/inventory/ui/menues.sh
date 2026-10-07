
source "$(dirname "${BASH_SOURCE[0]}")/../../shared/utils/validations.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../../shared/utils/helpers.sh"

welcome_message() {
    local c_blue="\033[1;34m"
    local c_bold="\033[1m"
    local c_dim="\033[2m"
    local c_reset="\033[0m"

    printf "${c_blue}+-----------------------------------------------------------+${c_reset}\n"
    printf "${c_blue}|${c_reset}                                                           ${c_blue}|${c_reset}\n"
    printf "${c_blue}|${c_reset}          ${c_bold}¡Bienvenido al sistema de inventario!${c_reset}            ${c_blue}|${c_reset}\n"
    printf "${c_blue}|${c_reset}              ${c_dim}Presiona CTRL+C para salir${c_reset}                   ${c_blue}|${c_reset}\n"
    printf "${c_blue}|${c_reset}                                                           ${c_blue}|${c_reset}\n"
    printf "${c_blue}+-----------------------------------------------------------+${c_reset}\n"
    printf "\n"
}

show_inventory_menu(){
    local c_bold="\033[1m"
    local c_reset="\033[0m"

    printf "\n"
    printf "=============================================================\n"
    printf "                    ${c_bold}MENÚ DE INVENTARIO${c_reset}\n"
    printf "=============================================================\n"
    printf " 1. Alta producto (ID 0 a %d)\n"
    printf " 2. Baja producto\n"
    printf " 3. Modificación producto (ID 0 a %d)\n"
    printf " 4. Mostrar inventario\n"
    printf " 5. Generar archivo HTML\n"
    printf " 6. Buscar producto por nombre\n"
    printf " 7. Salir\n"
    printf "=============================================================\n"
    printf "\n"
}

show_products_array(){
    local -n array_ref=$1
    local -i array_length=$2
    local available_text=""

    if((array_length>0)); then
    
        printf "%-5s %-15s %-15s %-8s %-10s %-10s %-8s\n" "ID" "NOMBRE" "CATEGORIA" "STOCK" "COSTO" "PRECIO" "ESTADO"
        printf "%s\n" "------------------------------------------------------------------------"

            for ((i=0; i<array_length; i++)); do
                if [[ -n "${array_ref[$i,id]}" ]]; then

                    if(( "${array_ref[$i,activo]}"==1 ));then
                        available_text="Disponible"
                    else
                        available_text="No Disponible"
                    fi

                    printf "%-5s %-15s %-15s %-8s %-9s %-9s %-8s\n" \
                        "${array_ref[$i,id]}" \
                        "${array_ref[$i,nombre]}" \
                        "${array_ref[$i,categoria]}" \
                        "${array_ref[$i,stock]}" \
                        "${array_ref[$i,costo]}" \
                        "${array_ref[$i,precio]}"\
                        "${available_text}"
                fi
            done
    else 
        printf "No se encontraron productos. \n"
    fi
}

show_products_array_paginated() {
    local -n array_ref=$1
    local -i array_length=$2
    local -i page_size=${3:-5}

    if (( array_length == 0 )); then
        printf "No se encontraron productos.\n"
        return
    fi

    local -A unique_ids=()
    local key
    for key in "${!array_ref[@]}"; do
        local id_part="${key%%,*}"
        unique_ids["$id_part"]=1
    done

    local valid_ids=()
    readarray -t valid_ids < <(printf '%s\n' "${!unique_ids[@]}" | sort -n)

    local -i total_items=${#valid_ids[@]}
    local -i total_pages=$(( (total_items + page_size - 1) / page_size ))
    local -i current_page=1
    local option=""

    while true; do
        clear
        local -i start_index=$(( (current_page - 1) * page_size ))
        local -i end_index=$(( start_index + page_size ))
        (( end_index > total_items )) && end_index=$total_items

        printf "=== LISTADO DE PRODUCTOS (Página %d de %d) ===\n\n" "$current_page" "$total_pages"
        printf "%-5s %-15s %-15s %-8s %-10s %-10s %-8s\n" "ID" "NOMBRE" "CATEGORIA" "STOCK" "COSTO" "PRECIO" "ESTADO"
        printf "%s\n" "------------------------------------------------------------------------"

        for ((idx=start_index; idx<end_index; idx++)); do
            local i="${valid_ids[$idx]}"
            if [[ -n "${array_ref[$i,id]}" ]]; then
                local available_text="No Disponible"
                if (( array_ref[$i,activo] == 1 )); then
                    available_text="Disponible"
                fi

                printf "%-5s %-15s %-15s %-8s %-9s %-9s %-8s\n" \
                    "${array_ref[$i,id]}" \
                    "${array_ref[$i,nombre]}" \
                    "${array_ref[$i,categoria]}" \
                    "${array_ref[$i,stock]}" \
                    "${array_ref[$i,costo]}" \
                    "${array_ref[$i,precio]}" \
                    "${available_text}"
            fi
        done

        printf "%s\n" "------------------------------------------------------------------------"
        printf "Mostrando %d - %d de %d productos.\n\n" $((start_index + 1)) "$end_index" "$total_items"
        printf " [A] Anterior |  [S] Siguiente  |  [Q] Volver al menú: "
        read -r -n 1 option
        echo ""

        case "${option,,}" in
            s)
                if (( current_page < total_pages )); then
                    (( current_page++ ))
                fi
                ;;
            a)
                if (( current_page > 1 )); then
                    (( current_page-- ))
                fi
                ;;
            q)
                break
                ;;
        esac
    done
}

#refactor para encapsular procesamiento de opciones
get_option_from_user_and_execute_inventory_action(){
    
    local -r -i OPTION_CREATE=1
    local -r -i OPTION_DELETE=2
    local -r -i OPTION_UPDATE=3
    local -r -i OPTION_SHOW_ALL=4
    local -r -i OPTION_GENERATE_HTML=5
    local -r -i OPTION_SEARCH_ONE_BY_NAME=6
    local -r -i OPTION_EXIT=7

    local action_option=0
    local -n inventory_g_ref=$1    
    local -n inventory_length_g_ref=$2

    local products_categories=("frutas" "verduras" "enlatados" "almacen" "otros")


    while [[ "$action_option" != "$OPTION_EXIT" ]]; do
        show_inventory_menu
        local -i id=0
        local -A p_temp

        read -rn 1 -p "Opcion: " action_option

        case $action_option in
            $OPTION_CREATE)

                clear_screen

                ! alpha_field_with_validation "Ingrese el nombre del producto a crear: " nombre_temp && continue

                local -i is_repeated=0
                p_temp=()

                search_products_by_name "${nombre_temp}" p_temp is_repeated "$inventory_length_g_ref" inventory_g_ref

                if(( ${is_repeated} > 0 )); then

                    echo "¡El producto ya existe! No puede duplicar el nombre de productos."

                else

                    ! enum_field_with_validation "Ingrese Categoria: " products_categories categoria_temp && continue

                    ! numeric_field_with_validation "Ingrese Stock: " stock_temp && continue

                    ! decimal_field_with_validation "Ingrese Costo de Compra (proveedor): " costo_temp && continue

                    ! decimal_field_with_validation "Ingrese Precio de venta: " precio_temp && continue

                    p_temp=()

                    p_temp[id]="${inventory_length_g_ref}"
                    p_temp[nombre]="$nombre_temp"
                    p_temp[categoria]="$categoria_temp"
                    p_temp[stock]="$stock_temp"
                    p_temp[costo]="$costo_temp"
                    p_temp[precio]="$precio_temp"
                    p_temp[activo]=1

                    clear_screen

                    create_product p_temp inventory_g_ref
                
                    update_array_length_variable_by_ref inventory_g_ref inventory_length_g_ref

                    save_product_action_to_journal "INSERT" p_temp
                fi
                ;;
            $OPTION_DELETE)

                clear_screen

                ! alpha_field_with_validation "Ingrese el nombre del producto a eliminar: " nombre_temp && continue

                local -A p_temp_with_index=()
                quantity_of_p_found=0

                search_products_by_name "$nombre_temp" p_temp_with_index quantity_of_p_found "$inventory_length_g_ref" inventory_g_ref

                if (( quantity_of_p_found > 1 )); then
                    printf "Ese nombre corresponde a más de un producto. No se puede proceder con la petición. \n"
                    continue
                elif (( quantity_of_p_found == 0 )); then
                    printf "No se encontró ningún producto con ese nombre. \n"
                    continue
                fi

                p_temp[id]="${p_temp_with_index[0,id]}"
                p_temp[nombre]="${p_temp_with_index[0,nombre]}"
                p_temp[categoria]="${p_temp_with_index[0,categoria]}"
                p_temp[stock]="${p_temp_with_index[0,stock]}"
                p_temp[costo]="${p_temp_with_index[0,costo]}"
                p_temp[precio]="${p_temp_with_index[0,precio]}"
                p_temp[activo]="${p_temp_with_index[0,activo]}"

                clear_screen

                delete_product "${p_temp[id]}" inventory_g_ref && save_product_action_to_journal "DELETE" p_temp
                ;;
            $OPTION_UPDATE)

                clear_screen

                ! alpha_field_with_validation "Ingrese el nombre actual del producto a modificar: " nombre_temp && continue

                local -A p_temp_with_index=()
                quantity_of_p_found=0

                search_products_by_name "$nombre_temp" p_temp_with_index quantity_of_p_found "$inventory_length_g_ref" inventory_g_ref

                if (( quantity_of_p_found > 1 )); then
                    printf "Ese nombre corresponde a más de un producto. No se puede proceder con la petición. \n"
                    continue
                elif (( quantity_of_p_found == 0 )); then
                    printf "No se encontró ningún producto con ese nombre. \n"
                    continue
                fi

                p_temp=()

                p_temp[id]="${p_temp_with_index[0,id]}"
                p_temp[nombre]="${p_temp_with_index[0,nombre]}"
                p_temp[categoria]="${p_temp_with_index[0,categoria]}"
                p_temp[stock]="${p_temp_with_index[0,stock]}"
                p_temp[costo]="${p_temp_with_index[0,costo]}"
                p_temp[precio]="${p_temp_with_index[0,precio]}"
                p_temp[activo]="${p_temp_with_index[0,activo]}"

                nombre_temp=""
                categoria_temp=""
                stock_temp=""
                costo_temp=""
                precio_temp=""

                ! alpha_field_with_validation "Ingrese el nuevo Nombre: [Actual: ${p_temp[nombre]}] - (enter para conservar el actual)" nombre_temp "not_required" && continue
                p_temp[nombre]="${nombre_temp:-${p_temp[nombre]}}"

                ! enum_field_with_validation "Ingrese Categoria: [Actual: ${p_temp[categoria]}] - (enter para conservar el original)" products_categories categoria_temp "not_required" && continue
                p_temp[categoria]="${categoria_temp:-${p_temp[categoria]}}"

                ! numeric_field_with_validation "Ingrese Stock: [Actual: ${p_temp[stock]}] - (enter para conservar el original)" stock_temp "not_required" && continue
                p_temp[stock]="${stock_temp:-${p_temp[stock]}}"

                ! decimal_field_with_validation "Ingrese Costo de Compra (proveedor): [Actual: ${p_temp[costo]}] - (enter para conservar el original)" costo_temp "not_required" && continue
                p_temp[costo]="${costo_temp:-${p_temp[costo]}}"

                ! decimal_field_with_validation "Ingrese Precio: [Actual: ${p_temp[precio]}] - (enter para conservar el original)" precio_temp "not_required" && continue
                p_temp[precio]="${precio_temp:-${p_temp[precio]}}"

                if (( "${p_temp[activo]}"==0 )); then
                    local -i reactivate=0
                    local reactivate_options=( 0 1 )
                    ! enum_field_with_validation "¿Desea reactivar el producto? Ingrese: 0 para mantener borrado | 1 para reactivar el producto." reactivate_options reactivate && continue

                    (( "${reactivate}" == 1)) && p_temp[activo]=1
                fi

                clear_screen

                update_product p_temp inventory_g_ref && save_product_action_to_journal "UPDATE" p_temp
                ;;
            $OPTION_SHOW_ALL)

                clear_screen
            
                show_products_array_paginated inventory_g_ref inventory_length
                ;;
            $OPTION_GENERATE_HTML)

                clear_screen
            
                generate_html $1
                ;;
            $OPTION_SEARCH_ONE_BY_NAME)

                clear_screen

                local -i products_found_length=0
                local -A products_found=()                

                ! alpha_field_with_validation "Ingrese el Nombre del producto a buscar: " nombre_temp && continue

                search_products_by_partial_name "$nombre_temp" products_found products_found_length "$inventory_length_g_ref" inventory_g_ref

                clear_screen

                show_products_array products_found products_found_length
                ;;
            $OPTION_EXIT)
                printf "\nSaliendo del programa...\n"
                ;;
            *)
                printf "\nOpcion invalida.\n"
                ;;
        esac
    done

    return 0
}