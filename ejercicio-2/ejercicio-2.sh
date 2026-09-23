#!/usr/bin/env bash

#▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ My Functions ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀#

#refactor para este bloque que vi repetido
es_id_valido() {
    local -i id=$1
    if (( id < 0 || id >= MAX )); then
        printf "Error: ID fuera de rango.\n"
        return 1
    fi
    
    return 0
}

update_array_length_variable_by_ref(){
    local -n inventory_ref=$1
    local -n inventory_length_ref=$2
    local -i new_inventory_length=0

    for((i=0; i<MAX ;i++)); do

        if [[ -n "${inventory_ref[$i,id]}" ]]; then
            ((new_inventory_length++))
        fi

    done

    inventory_length_ref="${new_inventory_length}"
}

#refactor para encapsular menu
show_menu(){
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

#refactor para encapsular procesamiento de opciones
get_option_from_user_and_execute_action(){
    
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
        show_menu
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

                    save_data_to_tsv $1
                fi
                ;;
            $OPCION_BAJA)
                read -rp "Ingrese ID a eliminar (0-$((MAX - 1))): " id

                baja "$id"

                save_data_to_tsv $1
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
                save_data_to_tsv $1
                ;;
            $OPCION_MOSTRAR)
                mostrar
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

#▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ Product Functions ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀#

search_products_by_partial_name(){
    local -r product_name=$1
    local -n product_found_ref=$2
    local -n quantity_of_products_found=$3

    product_found_ref=()
    quantity_of_products_found=0

    shopt -s nocasematch

    for ((i=0; i<MAX; i++)); do
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

    for ((i=0; i<MAX; i++)); do
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

show_products_array(){
    local -n array_ref=$1
    local -i array_length=$2

    if((array_length>0)); then
    
        printf "%-5s %-15s %-15s %-8s %-10s %-10s %-8s\n" "ID" "NOMBRE" "CATEGORIA" "STOCK" "COSTO" "PRECIO" "ESTADO"
        printf "%s\n" "------------------------------------------------------------------------"

            for ((i=0; i<array_length; i++)); do
                if [[ -n "${array_ref[$i,id]}" ]]; then
                    printf "%-5s %-15s %-15s %-8s %-9s %-9s %-8s\n" \
                        "${array_ref[$i,id]}" \
                        "${array_ref[$i,nombre]}" \
                        "${array_ref[$i,categoria]}" \
                        "${array_ref[$i,stock]}" \
                        "${array_ref[$i,costo]}" \
                        "${array_ref[$i,precio]}"\
                        "${array_ref[$i,activo]}"
                fi
            done
    else 
        printf "No se encontraron productos. \n"
    fi
}

#▀▀▀▀▀▀▀▀ EOC printing functions for html template ▀▀▀▀▀▀▀▀#

print_table_headers() {
    cat << EOF > vista_inventario.html
    
    <!DOCTYPE html>
        <html>
        <head>
            <title> Reporte de Productos </title>
        </head>
        <body>
            <h1> Listado de Productos </h1>
            <table border="1">
                <thead>
                    <tr>
                        <th> ID </th>
                        <th> Nombre </th>
                        <th> Categoría </th>
                        <th> Stock </th>
                        <th> Costo compra </th>
                        <th> Precio venta </th>
                    </tr>
                </thead>
                <tbody>
EOF
}

print_table_headers() {
    cat << EOF > vista_inventario.html
    
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Reporte de Productos</title>
        <style>
            :root {
                --bg-color: #f4f6f9;
                --card-bg: #ffffff;
                --primary: #6c5ce7;
                --primary-light: #a29bfe;
                --text-color: #2d3436;
                --border-color: #dfe6e9;
                --zebra-bg: #f8f9fa;
            }

            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background-color: var(--bg-color);
                color: var(--text-color);
                margin: 0;
                padding: 20px;
                display: flex;
                justify-content: center;
            }

            .container {
                width: 100%;
                max-width: 800px;
                background: var(--card-bg);
                padding: 25px;
                border-radius: 12px;
                box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
            }

            h1 {
                text-align: center;
                color: var(--primary);
                margin-bottom: 20px;
                font-size: 1.8rem;
            }

            .table-responsive {
                overflow-x: auto;
            }

            table {
                width: 100%;
                border-collapse: collapse;
                border-radius: 8px;
                overflow: hidden;
            }

            caption {
                caption-side: top;
                text-align: left;
                font-weight: bold;
                color: #636e72;
                margin-bottom: 10px;
                text-transform: uppercase;
                font-size: 0.85rem;
                letter-spacing: 1px;
            }

            th {
                background-color: var(--primary-light);
                color: #ffffff;
                padding: 12px 15px;
                text-align: left;
                font-weight: 600;
            }

            td {
                padding: 12px 15px;
                border-bottom: 1px solid var(--border-color);
            }

            tbody tr:nth-child(even) {
                background-color: var(--zebra-bg);
            }

            tbody tr:hover {
                background-color: #eef2f7;
                transition: background-color 0.2s ease;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Listado de Productos</h1>
            <div class="table-responsive">
                <table border="0">
                    <caption>Inventario Actual</caption>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Nombre</th>
                            <th>Categoria</th>
                            <th>Stock</th>
                            <th>Costo</th>
                            <th>Precio</th>
                            <th>Estado</th>
                        </tr>
                    </thead>
                    <tbody>
EOF
}

print_table_body() {
    local -n i_ref=$1

    for ((i=0; i<MAX; i++)); do
        cat << EOF >> vista_inventario.html
        <tr>
            <td> ${i_ref[$i,id]} </td> <td> ${i_ref[$i,nombre]} </td> <td> ${i_ref[$i,categoria]} </td> <td> ${i_ref[$i,stock]} </td> <td> ${i_ref[$i,costo]} </td> <td> ${i_ref[$i,precio]} </td> <td> ${i_ref[$i,activo]} </td>
        </tr>
EOF
    done
}

print_table_footer() {
    cat << EOF >> vista_inventario.html

                        </tbody>
                    </table>
                </div>
            </div>
        </body>
    </html>
EOF
}

generate_html() {
    local -n inv_ref=$1

    print_table_headers
    print_table_body inv_ref
    print_table_footer
}

#▀▀▀▀▀▀▀▀ tsv functions ▀▀▀▀▀▀▀▀#

load_data_into_array_from_tsv(){
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

save_data_to_tsv(){
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

save_user_into_tsv(){
    local username=$1
    local password=$2

    printf "%s\t%s\n" \
        "${username}" \
        "${password}" >> datos_usuarios.tsv

    return 0
}

#▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ Auth Functions ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀#

username_already_exists(){
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

create_user(){
    local username=""
    local password=""

    clear_screen
    
    read -rp $'Ingresa tu nombre de usuario deseado:\n' username

    if [[ -f datos_usuarios.tsv ]]; then
        while username_already_exists "${username}" ; do
            printf "¡El usuario ya existe! Por favor, ingresa otro. \n"
            read -rp $'Ingresa tu nombre de usuario deseado: \n' username
        done
    fi

    read -rsp $'Ingresa una contraseña para tu usuario: \n' password
    echo ""

    local hashed_password="$(hash_password "${password}")"

    if save_user_into_tsv "${username}" "${hashed_password}" ; then
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

    if [[ ! -f datos_usuarios.tsv ]]; then
        printf 'No se encuentra el archivo de usuarios. Por favor, primero registra un usuario para crearlo. \n'
        return 1
    fi

    while (( tries<5 )); do
        read -rp $'Ingresa tu usuario: \n' username

        hashed_password="$( find_hashed_password_by_username "${username}" )"

        if [[ -n "${hashed_password}" ]]; then
            break
        fi

        (( tries++ ))
        printf 'No se ha encontrado registro para ese usuario. Por favor, chequee que sea correcto. Intentos restantes %d\n' "$((5 - tries))"
    done        

    if (( tries>=5 )); then
        printf "¡Intentos fallidos maximos alcanzados!"
        exit 1
    fi

    tries=0

    while (( tries<3 )); do
        read -rsp $'Ingresa tu contraseña: \n' password
        echo ""

        password="$(hash_password "${password}")" 

        if [[ "${hashed_password}" == "${password}" ]]; then
            printf "Login exitoso. ¡Bienvenido! \n"
            return 0
        fi

        (( tries++ ))
        printf "Contraseña incorrecta. (intentos restantes "$(( 3 - tries ))")"
    done

    printf "¡Intentos fallidos maximos alcanzados!"
    exit 1
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

alta() {
    local -n prod_ref=$1
    local -i id=${prod_ref[id]} 

    if ! es_id_valido "$id"; then
        return 1
    fi

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

baja() {
    local -i id=$1

    if ! es_id_valido "$id"; then
        return
    fi

    if [[ ${inventario[$id,activo]:-0} -eq 1 ]]; then
        inventario[$id,activo]=0
        printf "Producto %d dado de baja.\n" "$id"
    else
        printf "El producto ya fue dado de baja.\n"
    fi
}

mostrar() {
    local -i i=0
    printf "\nLISTADO:\n"
    printf "%-5s %-15s %-15s %-8s %-10s %-10s %-8s\n" "ID" "NOMBRE" "CATEGORIA" "STOCK" "COSTO" "PRECIO" "ESTADO"
    printf "%s\n" "------------------------------------------------------------------------"

        for ((i=0; i<MAX; i++)); do
            if [[ -n "${inventario[$i,id]}" ]]; then
                printf "%-5s %-15s %-15s %-8s $%-9s $%-9s %-8s\n" \
                    "${inventario[$i,id]}" \
                    "${inventario[$i,nombre]}" \
                    "${inventario[$i,categoria]}" \
                    "${inventario[$i,stock]}" \
                    "${inventario[$i,costo]}" \
                    "${inventario[$i,precio]}"\
                    "${inventario[$i,activo]}"
            fi
        done
}

modificar() {
    local -n produc_ref=$1
    local -i id=${produc_ref[id]} 

    if ! es_id_valido "$id"; then
        return
    fi

    if [[ -n "${inventario[$id,id]}" ]] && [[ ${inventario[$id,activo]:-0} -eq 1 ]]; then

        inventario[$id,nombre]="${produc_ref[nombre]}"
        inventario[$id,categoria]="${produc_ref[categoria]}"
        inventario[$id,stock]="${produc_ref[stock]}"
        inventario[$id,costo]="${produc_ref[costo]}"
        inventario[$id,precio]="${produc_ref[precio]}"

        printf "Producto %d (%s - categoria: %s) modificado correctamente con costo $%.2f. precio $%.2f.\n" \
        "$id" "${produc_ref[nombre]}" "${produc_ref[categoria]}" "${produc_ref[costo]}" "${produc_ref[precio]}"
        
    else
        printf "El producto no existe o está dado de baja.\n"
    fi
}

#▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ · ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀#

main() {
    declare -r -i MAX=50
    declare -A inventario=()
    declare -i inventory_length=0

    bienvenida

    if ! get_option_from_user_and_execute_login_or_register; then
        return 1
    fi
  
    load_data_into_array_from_tsv inventario

    update_array_length_variable_by_ref inventario inventory_length

    get_option_from_user_and_execute_action inventario inventory_length

    return 0
}

main