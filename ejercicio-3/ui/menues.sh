#!/usr/bin/env bash

bienvenida() {
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
    printf " 1. Alta producto (ID 0 a %d)\n" $((MAX - 1))
    printf " 2. Baja producto\n"
    printf " 3. Modificación producto (ID 0 a %d)\n" $((MAX - 1))
    printf " 4. Mostrar inventario\n"
    printf " 5. Generar archivo HTML\n"
    printf " 6. Buscar producto por nombre\n"
    printf " 7. Salir\n"
    printf "=============================================================\n"
    printf "\n"
}

show_auth_menu(){

    printf "\n \n"
    local c_bold="\033[1m"
    local c_reset="\033[0m"

    printf "=============================================================\n"
    printf "                  ${c_bold}SISTEMA DE AUTENTICACIÓN${c_reset}\n"
    printf "=============================================================\n"
    printf "1. Registrar un nuevo usuario\n"
    printf "2. Acceder a tu usuario\n"
    printf "3. Salir\n\n"
    
}

#refactor para encapsular procesamiento de opciones
get_option_from_user_and_execute_inventory_action(){
    
    local -r -i OPCION_ALTA=1
    local -r -i OPCION_BAJA=2
    local -r -i OPCION_MODIFICAR=3
    local -r -i OPCION_MOSTRAR=4
    local -r -i OPCION_GENERAR_HTML=5
    local -r -i OPCION_BUSCAR_PRODUCTO_POR_NOMBRE=6
    local -r -i OPCION_SALIR=7

    local -i opcion=0
    local -n inventory_g_ref=$1    
    local -n inventory_length_g_ref=$2


    while [[ "$opcion" != "$OPCION_SALIR" ]]; do
        show_inventory_menu
        local -i id=0
        local -A p_temp

        read -rp "Opcion: " opcion

        case $opcion in
            $OPCION_ALTA)
                read -rp "Ingrese Nombre: " nombre_temp

                local -i is_repeated=0
                p_temp=()

                search_products_by_name "${nombre_temp}" p_temp is_repeated

                if(( ${is_repeated} > 0 )); then
                    echo "¡El producto ya existe! No puede duplicar el nombre de productos."
                else
                    read -rp "Ingrese Categoria: " categoria_temp
                    read -rp "Ingrese Stock: " stock_temp
                    read -rp "Ingrese Costo de Compra (proveedor): " costo_temp
                    read -rp "Ingrese Precio de venta: " precio_temp

                    p_temp[id]="${inventory_length_g_ref}"
                    p_temp[nombre]="$nombre_temp"
                    p_temp[categoria]="$categoria_temp"
                    p_temp[stock]="$stock_temp"
                    p_temp[costo]="$costo_temp"
                    p_temp[precio]="$precio_temp"
                    p_temp[activo]=1

                    alta p_temp
                
                    update_array_length_variable_by_ref inventory_g_ref inventory_length_g_ref

                    save_product_wal "INSERT" p_temp
                fi
                ;;
            $OPCION_BAJA)
                read -rp "Ingrese ID a eliminar (0-$((MAX - 1))): " id

                baja "$id"

                save_product_wal "DELETE" p_temp
                ;;
            $OPCION_MODIFICAR)
                read -rp "Ingrese ID (0-$((MAX - 1))): " id
                read -rp "Ingrese Nombre: " nombre_temp
                read -rp "Ingrese Categoria: " categoria_temp
                read -rp "Ingrese Stock: " stock_temp
                read -rp "Ingrese Costo de Compra (proveedor): " costo_temp
                read -rp "Ingrese Precio: " precio_temp

                p_temp[id]="$id"
                p_temp[nombre]="$nombre_temp"
                p_temp[categoria]="$categoria_temp"
                p_temp[stock]="$stock_temp"
                p_temp[costo]="$costo_temp"
                p_temp[precio]="$precio_temp"
                p_temp[activo]=1

                modificar p_temp
                save_product_wal "UPDATE" p_temp
                ;;
            $OPCION_MOSTRAR)
                show_products_array inventory_g_ref inventory_length
                ;;
            $OPCION_GENERAR_HTML)
                generate_html $1
                ;;
            $OPCION_BUSCAR_PRODUCTO_POR_NOMBRE)
                local -i products_found_length=0
                local -A products_found=()                

                read -rp "Ingrese Nombre: " nombre_temp

                search_products_by_partial_name "$nombre_temp" products_found products_found_length

                show_products_array products_found products_found_length
                ;;
            $OPCION_SALIR)
                printf "\nSaliendo del programa...\n"
                ;;
            *)
                printf "\nOpcion invalida.\n"
                ;;
        esac
    done

    return 0
}

get_option_from_user_and_execute_login_or_register(){
    local -r -i OPTION_REGISTER=1
    local -r -i OPTION_LOGIN=2
    local -r -i OPTION_EXIT=3

    local -i option=0

    while [[ "$option" != "$OPTION_EXIT" ]]; do
        show_auth_menu

        read -rp "Opcion: " option

        case $option in
            $OPTION_REGISTER)
                    create_user
                ;;
            $OPTION_LOGIN)
                    if auth_user ; then
                        return 0
                    fi
                ;;
            $OPTION_EXIT)
                printf "Saliendo del programa..."
                exit 0
            ;;
            *)
                printf "\nOpcion invalida.\n"
                ;;
        esac
    done
}

#▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ · ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀#