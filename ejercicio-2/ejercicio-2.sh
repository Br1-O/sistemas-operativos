#!/usr/bin/env bash

declare -r -i MAX=50
declare -A inventario

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

#refactor para encapsular menu
show_menu(){
    printf "\nACCIONES:\n"
        printf "1. Alta producto (ID 0 a %d)\n" $((MAX - 1))
        printf "2. Baja producto\n"
        printf "3. Modificación producto (ID 0 a %d)\n" $((MAX - 1))
        printf "4. Mostrar inventario\n"
        printf "5. Generar archivo html\n"
        printf "6. Salvar \n"
        printf "7. Salir\n"
}

#refactor para encapsular procesamiento de opciones
get_option_from_user_and_execute_action(){
    
    local -r -i OPCION_ALTA=1
    local -r -i OPCION_BAJA=2
    local -r -i OPCION_MODIFICAR=3
    local -r -i OPCION_MOSTRAR=4
    local -r -i OPCION_GENERAR_HTML=5
    local -r -i OPCION_SALVAR_TSV=6
    local -r -i OPCION_SALIR=7

    local -i opcion=0
    local -n inventory_ref=$1

    while [[ "$opcion" != "$OPCION_SALIR" ]]; do
        show_menu
        local -i id=0
        local -A p_temp

        read -rp "Opcion: " opcion

        case $opcion in
            $OPCION_ALTA)
                read -rp "Ingrese ID (0-$((MAX - 1))): " id
                read -rp "Ingrese Nombre: " nombre_temp
                read -rp "Ingrese Categoria: " categoria_temp
                read -rp "Ingrese Stock: " stock_temp
                read -rp "Ingrese Costo de Compra (proveedor): " costo_temp
                read -rp "Ingrese Precio de venta: " precio_temp

                p_temp[id]="$id"
                p_temp[nombre]="$nombre_temp"
                p_temp[categoria]="$categoria_temp"
                p_temp[stock]="$stock_temp"
                p_temp[costo]="$costo_temp"
                p_temp[precio]="$precio_temp"
                p_temp[activo]=1

                alta p_temp
                
                save_data_to_tsv $1
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
            $OPCION_SALVAR_TSV)
                save_data_to_tsv $1
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

        #check if the first value if empty, if so, ignore
        [[ -z "$id" ]] && continue;

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
        if [[ -n "${inventario[$i,id]}" ]]; then
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

#▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ · ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀#


bienvenida() {
    local c_blue="\033[1;34m"
    local c_bold="\033[1m"
    local c_dim="\033[2m"
    local c_reset="\033[0m"

    printf "${c_blue}┌─────────────────────────────────────────────────────────────┐${c_reset}\n"
    printf "${c_blue}│${c_reset}                                                             ${c_blue}│${c_reset}\n"
    printf "${c_blue}│${c_reset}            ${c_bold}¡Bienvenido al sistema de inventario!${c_reset}            ${c_blue}│${c_reset}\n"
    printf "${c_blue}│${c_reset}                ${c_dim}Presiona CTRL+C para salir${c_reset}                   ${c_blue}│${c_reset}\n"
    printf "${c_blue}│${c_reset}                                              ${c_blue}               │${c_reset}\n"
    printf "${c_blue}└─────────────────────────────────────────────────────────────┘${c_reset}\n"
    printf "\n"
}

autenticar() {
    local -i intentos=0
    local clave=""

    while (( intentos < 3 )); do
        read -rp "Ingrese clave (1234): " clave

        if [[ "$clave" == "1234" ]]; then
            printf "Acceso concedido.\n"
            return 0
        fi

        intentos=$((intentos + 1))
        printf "Clave incorrecta (%d/3 intentos).\n" "$intentos"
    done

    return 1
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
    bienvenida

    if ! autenticar; then
        printf "\nAcceso denegado.\n"
        return 1
    fi
  
    load_data_into_array_from_tsv inventario

    get_option_from_user_and_execute_action inventario

    return 0
}

main
