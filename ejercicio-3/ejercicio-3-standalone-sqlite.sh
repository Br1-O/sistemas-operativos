#!/usr/bin/env bash
# Generado automáticamente (sqlite)

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

get_value_with_cancel_action_option() {
    local original_message="$1"
    local -n out_value_ref=$2
    local user_input=""

    read -r -p "${original_message}("q" para cancelar) " user_input

    if [[ "${user_input,,}" == "q" ]]; then
        clear_screen
        return 1
    fi

    out_value_ref="$user_input"
    return 0
}

update_array_length_variable_by_ref(){
    local -n inventory_ref=$1
    local -n inventory_length_ref=$2
    local -i new_inventory_length=0

    local count=0
    for key in "${!inventory_ref[@]}"; do
        [[ "$key" == *",id" ]] && ((count++))
    done

    inventory_length_ref=$count
}


is_numeric() {
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

is_decimal() {
    if [[ "$1" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
        return 0
    else
        return 1
    fi
}

is_alpha() {
     if [[ "$1" =~ ^[a-zA-ZáéíóúÁÉÍÓÚñÑ[:space:]]+$ ]]; then
        return 0
    else
        return 1
    fi
}

is_not_empty(){
    if [[ -z "$1" ]]; then
            return 1
    fi

    return 0
}

is_not_empty_field_with_validation(){
    local field_msg=$1
    local -n field_reference=$2 
                
    while true; do

        is_not_empty "${field_reference}" && break

        printf $'No puedes ingresar un valor vacio para el campo.\n'

        ! get_value_with_cancel_action_option "${field_msg}" field_reference && return 1 

    done

    return 0
}

alpha_field_with_validation(){
    local field_message=$1
    local -n field_ref=$2 
    local is_required="${3:-required}"

    ! get_value_with_cancel_action_option "${field_message}" field_ref && return 1 

    [[ "${is_required}" == "required" ]] && is_not_empty_field_with_validation "${field_message}" field_ref
    [[ "${is_required}" == "not_required" ]] && [[ -z "${field_ref}" ]] && return 0
                
    while true; do

        is_alpha "${field_ref}" && break

        printf "El campo solo puede poseer letras y espacios.\n"

        ! get_value_with_cancel_action_option "${field_message}" field_ref && return 1 

    done

    return 0
}

enum_field_with_validation(){
    local field_message=$1
    local -n valid_values=$2
    local -n field_ref=$3
    local is_required="${4:-required}"
    
    local joined_values
    joined_values=$(IFS=", "; echo "${valid_values[*]}")


    ! get_value_with_cancel_action_option "${field_message} [Valores posibles: ${joined_values}]: " field_ref && return 1 


    [[ "${is_required}" == "not_required" ]] && [[ -z "${field_ref}" ]] && return 0

    while true; do

        local value_match=false
        local val
        for val in "${valid_values[@]}"; do
            if [[ "$field_ref" == "$val" ]]; then
                value_match=true
                break
            fi
        done

        if [ "$value_match" = true ]; then
            break
        fi

        printf "Error: El valor introducido no es válido.\n"
        printf "Debe elegir una de las siguientes opciones: %s\n" "${joined_values}"
        
        ! get_value_with_cancel_action_option "${field_message} [Valores posibles: ${joined_values}]: " field_ref && return 1 
    done
    
    return 0
}

numeric_field_with_validation(){
    local field_message=$1
    local -n field_ref=$2 
    local is_required="${3:-required}"

    ! get_value_with_cancel_action_option "${field_message}" field_ref && return 1 

    [[ "${is_required}" == "required" ]] && is_not_empty_field_with_validation "${field_message}" field_ref
    [[ "${is_required}" == "not_required" ]] && [[ -z "${field_ref}" ]] && return 0
                
    while ! is_numeric "${field_ref}"; do

        printf "El campo solo puede poseer números.\n"

    ! get_value_with_cancel_action_option "${field_message}" field_ref && return 1 

    done

    return 0
}

decimal_field_with_validation(){
    local field_message=$1
    local -n field_ref=$2
    local is_required="${3:-required}"

    ! get_value_with_cancel_action_option "${field_message}" field_ref && return 1 

    [[ "${is_required}" == "required" ]] && is_not_empty_field_with_validation "${field_message}" field_ref
    [[ "${is_required}" == "not_required" ]] && [[ -z "${field_ref}" ]] && return 0

                
    while ! is_decimal "${field_ref}"; do

        printf "El campo solo puede poseer números, comas y puntos.\n"

        ! get_value_with_cancel_action_option "${field_message}" field_ref && return 1 

    done

    return 0
}

check_product_already_exists_by_name(){
    local -n product_name=$1
    local -i p_already_exists=0
    local -A p_temp=()

    search_products_by_name "${nombre_temp}" p_temp p_already_exists

    if(( ${is_repeated} > 0 )); then

        echo "¡El producto ya existe! No puede duplicar el nombre de productos."
        return 1
    fi

    return 0
}


SQLITE_INVENTORY_PATH="shared/data/datos_inventario.db"
JOURNAL_INVENTORY_PATH="shared/data/datos_inventario.sqlite.journal"

#Dinamic schema for columns
INVENTORY_COLUMNS=("id" "nombre" "categoria" "stock" "costo" "precio" "activo")

CURRENT_USER="${CURRENT_USER:-sistema}"

load_inventory_into_array() {
    local -n invent_reference=$1

    journal_sqlite_init_db "$SQLITE_INVENTORY_PATH"

    journal_sqlite_load_to_assoc_array "$SQLITE_INVENTORY_PATH" invent_reference
}

save_product_action_to_journal() {
    local action="$1" # INSERT, UPDATE o DELETE
    local -n prod_reference=$2

    journal_sqlite_execute_action "$SQLITE_INVENTORY_PATH" "$action" prod_reference "$JOURNAL_INVENTORY_PATH" "$CURRENT_USER"
}

commit_inventory_journal() {
    sqlite3 "$SQLITE_INVENTORY_PATH" "PRAGMA wal_checkpoint(PASSIVE);" 2>/dev/null || true
}

journal_sqlite_init_db() {
    local db_path="$1"
    mkdir -p "$(dirname "$db_path")"

    sqlite3 "$db_path" <<EOF
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS Categories (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE NOT NULL CHECK (length(name) <= 50),
    description TEXT CHECK (length(description) <= 100)
);

CREATE TABLE IF NOT EXISTS Inventory (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(name) <= 50),
    category_id INTEGER NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    cost REAL NOT NULL DEFAULT 0.0,
    price REAL NOT NULL DEFAULT 0.0,
    active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
    FOREIGN KEY (category_id) REFERENCES Categories(id)
);

INSERT OR IGNORE INTO Categories (id, name, description) 
VALUES (1, 'General', 'Categoría por defecto');
EOF
}

journal_sqlite_load_to_assoc_array() {
    local db_path="$1"
    local -n target_array_ref=$2

    local query="SELECT i.id, i.name, c.name AS category, i.stock, i.cost, i.price, i.active FROM Inventory i INNER JOIN Categories c ON i.category_id = c.id;"

    while IFS='|' read -r id nombre categoria stock costo precio activo; do
        [[ -z "$id" ]] && continue

        target_array_ref["${id},id"]="$id"
        target_array_ref["${id},nombre"]="$nombre"
        target_array_ref["${id},categoria"]="$categoria"
        target_array_ref["${id},stock"]="$stock"
        target_array_ref["${id},costo"]="$costo"
        target_array_ref["${id},precio"]="$precio"
        target_array_ref["${id},activo"]="$activo"
    done < <(sqlite3 -separator '|' "$db_path" "$query")
}

journal_sqlite_execute_action() {
    local db_path="$1"
    local action="$2"
    local -n prod_ref=$3

    local journal_path="$4"
    local user="$5"

    local row=()
    for col in "${INVENTORY_COLUMNS[@]}"; do
        row+=("${prod_ref[$col]}")
    done

    local record_data="${row[@]}"
    
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    local state="ERROR"
    local exit_code=0

    case "$action" in
        INSERT)
            sqlite3 "$db_path" <<EOF
PRAGMA foreign_keys = ON;

INSERT OR IGNORE INTO Categories (name, description) 
VALUES ('${prod_ref[categoria]}', 'Categoría ${prod_ref[categoria]}');

INSERT INTO Inventory (id, name, category_id, stock, cost, price, active)
VALUES (
    ${prod_ref[id]},
    '${prod_ref[nombre]}',
    (SELECT id FROM Categories WHERE name = '${prod_ref[categoria]}'),
    ${prod_ref[stock]},
    ${prod_ref[costo]},
    ${prod_ref[precio]},
    ${prod_ref[activo]}
)
ON CONFLICT(id) DO UPDATE SET
    name=excluded.name,
    category_id=excluded.category_id,
    stock=excluded.stock,
    cost=excluded.cost,
    price=excluded.price,
    active=excluded.active;
EOF

        exit_code=$?

            ;;
        UPDATE)
            sqlite3 "$db_path" <<EOF
PRAGMA foreign_keys = ON;

INSERT OR IGNORE INTO Categories (name, description) 
VALUES ('${prod_ref[categoria]}', 'Categoría ${prod_ref[categoria]}');

UPDATE Inventory SET
    name='${prod_ref[nombre]}',
    category_id=(SELECT id FROM Categories WHERE name = '${prod_ref[categoria]}'),
    stock=${prod_ref[stock]},
    cost=${prod_ref[costo]},
    price=${prod_ref[precio]},
    active=${prod_ref[activo]}
WHERE id=${prod_ref[id]};
EOF
        exit_code=$?
            ;;
        DELETE)
            sqlite3 "$db_path" "UPDATE Inventory SET active=0 WHERE id=${prod_ref[id]};"

            exit_code=$?
            ;;
    esac

    if [[ $exit_code -eq 0 ]]; then
        state="DONE"
    fi

    local payload
    IFS=$'\t' eval 'payload="${record_data[*]}"'
        printf "%s\t%s\t%s\t%s\t%s\n" "$timestamp" "$user" "$action" "$payload" "$state" >> "$journal_path"

    return $exit_code
}

SQLITE_USERS_PATH="shared/data/datos_usuarios.db"

init_users_storage() {
    mkdir -p "$(dirname "$SQLITE_USERS_PATH")"
    sqlite3 "$SQLITE_USERS_PATH" <<EOF
CREATE TABLE IF NOT EXISTS Users (
    id INTEGER PRIMARY KEY,
    username TEXT UNIQUE NOT NULL CHECK (length(username) <= 50),
    password TEXT NOT NULL CHECK (length(password) <= 100)
);
EOF
}

hash_password() {
    local password_value="$1"
    local -n _out_hash_ref=$2

    read -r _out_hash_ref _ < <(printf '%s' "${password_value}" | sha256sum)
}

save_user() {
    local username="$1"
    local password="$2"
    local hashed_password=""

    hash_password "$password" hashed_password

    init_users_storage
    local safe_username="${username//\'/\'\'}"
    sqlite3 "$SQLITE_USERS_PATH" "INSERT INTO Users (username, password) VALUES ('$safe_username', '$hashed_password');" 2>/dev/null
    return $?
}

username_exists() {
    local entered_username="$1"

    if [[ ! -f "$SQLITE_USERS_PATH" ]]; then
        return 2
    fi

    local safe_username="${entered_username//\'/\'\'}"
    local count=0
    read -r count < <(sqlite3 "$SQLITE_USERS_PATH" "SELECT COUNT(*) FROM Users WHERE username='$safe_username';")

    if (( count > 0 )); then
        return 0
    else
        return 1
    fi
}

find_hashed_password_by_username() {
    local entered_username="$1"
    local -n _out_pass_ref=$2

    if [[ ! -f "$SQLITE_USERS_PATH" ]]; then
        return 1
    fi

    local safe_username="${entered_username//\'/\'\'}"
    _out_pass_ref=""
    read -r _out_pass_ref < <(sqlite3 "$SQLITE_USERS_PATH" "SELECT password FROM Users WHERE username='$safe_username';")

    if [[ -n "$_out_pass_ref" ]]; then
        return 0
    fi

    return 1
}

password_is_correct() {
    local entered_username="$1"
    local entered_password="$2"
    local db_password=""
    local input_hash=""

    if ! find_hashed_password_by_username "${entered_username}" db_password; then
        return 1
    fi

    hash_password "${entered_password}" input_hash

    if [[ "${input_hash}" == "${db_password}" ]]; then
        return 0
    fi

    return 1
}

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


declare CURRENT_USER=""

set_current_user() {
    CURRENT_USER="$1"
}

create_user(){
    local username=""
    local password=""

    clear_screen
    
    while true; do
        ! alpha_field_with_validation $'Ingresa tu nombre de usuario deseado:\n' username "required" && return 1

        if username_exists "${username}"; then
            printf "¡El usuario ya existe! Por favor, ingresa otro.\n\n"
        else
            break
        fi
    done

    read -rsp $'Ingresa una contraseña para tu usuario: \n' password
    echo ""

    while [[ -z "${password}" ]]; do
        read -rsp $'No puedes ingresar una contraseña vacia.\nIngresa una contraseña para tu usuario:\n' password
        echo ""
    done

    if save_user "${username}" "${password}" ; then
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

    while (( tries<5 )); do
        ! alpha_field_with_validation $'Ingresa tu usuario: \n' username && return 1

        if ! username_exists "${username}"; then
            (( tries++ ))
            printf 'No se ha encontrado registro para ese usuario. Por favor, chequee que sea correcto. Intentos restantes %d\n' "$((5 - tries))"
        else
            break
        fi
    done        

    if (( tries>=5 )); then
        printf "¡Intentos fallidos maximos alcanzados!"
        exit 1
    fi

    tries=0

    while (( tries<3 )); do
        read -rsp $'Ingresa tu contraseña: \n' password
        echo ""

        if [[ -z "${password}" ]]; then
            printf $'No puedes ingresar una contraseña vacia.\n'
            continue
        fi

        if password_is_correct "${username}" "${password}" ; then
            set_current_user "${username}"
            printf "Login exitoso. ¡Bienvenido, $username! \n"
            return 0
        fi

        (( tries++ ))
        printf "Contraseña incorrecta. (intentos restantes "$(( 3 - tries ))")"
    done

    printf "¡Intentos fallidos maximos alcanzados!"
    exit 1
}

HTML_VIEW_PATH="shared/data/vista_inventario.html"

print_table_headers() {
    cat << EOF 
    
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
                
                /* Colores pastel de stock */
                --stock-low-bg: #fde8e8;       /* Rojo pastel suave (Stock < 20) */
                --stock-low-text: #c0392b;
                --stock-mid-bg: #fff5cc;       /* Amarillo pastel suave (20 <= Stock <= 30) */
                --stock-mid-text: #b7791f;
                --stock-high-bg: #e6f4ea;      /* Verde pastel suave (Stock > 30) */
                --stock-high-text: #27ae60;

                /* Estilo no disponible (Gris suave) */
                --inactive-bg: #f1f2f6;
                --inactive-text: #a4b0be;
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

            /* Clases según nivel de stock */
            tbody tr.stock-low {
                background-color: var(--stock-low-bg) !important;
                color: var(--stock-low-text);
            }

            tbody tr.stock-mid {
                background-color: var(--stock-mid-bg) !important;
                color: var(--stock-mid-text);
            }

            tbody tr.stock-high {
                background-color: var(--stock-high-bg) !important;
                color: var(--stock-high-text);
            }

            /* Estilo para productos NO DISPONIBLES */
            tbody tr.row-inactive {
                background-color: var(--inactive-bg) !important;
                color: var(--inactive-text) !important;
                cursor: not-allowed;
                opacity: 0.8;
            }

            tbody tr.row-inactive:hover {
                background-color: #e4e7eb !important;
            }

            /* Reglas de Estado y Stock con Hover (Luminosidad / Oscurecimiento) */
            tbody tr.stock-low {
                background-color: var(--stock-low-bg) !important;
                color: var(--stock-low-text);
            }

            tbody tr.stock-low:hover {
                background-color: #fabbbb !important; /* Rojo pastel un poco más oscuro al pasar */
            }

            tbody tr.stock-mid {
                background-color: var(--stock-mid-bg) !important;
                color: var(--stock-mid-text);
            }

            tbody tr.stock-mid:hover {
                background-color: #ffe899 !important; /* Amarillo pastel un poco más oscuro */
            }

            tbody tr.stock-high {
                background-color: var(--stock-high-bg) !important;
                color: var(--stock-high-text);
            }

            tbody tr.stock-high:hover {
                background-color: #d1ebd6 !important; /* Verde pastel un poco más oscuro */
            }

            /* Estilo para productos NO DISPONIBLES */
            tbody tr.row-inactive {
                background-color: var(--inactive-bg) !important;
                color: var(--inactive-text) !important;
                cursor: not-allowed;
                opacity: 0.8;
            }

            tbody tr.row-inactive:hover {
                background-color: #e4e7eb !important; /* Gris un poco más oscuro */
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

    for ((i=0; i<inventory_length; i++)); do
        # Verificar que la clave exista en el mapa para evitar filas vacías
        if [[ -z "${i_ref[$i,id]}" ]]; then
            continue
        fi

        local estado_texto="no disponible"
        local row_class=""
        local -i stock_val=${i_ref[$i,stock]:-0}

        if [[ "${i_ref[$i,activo]}" == "1" ]]; then
            estado_texto="disponible"
            
            if (( stock_val < 20 )); then
                row_class="class=\"stock-low\""
            elif (( stock_val <= 30 )); then
                row_class="class=\"stock-mid\""
            else
                row_class="class=\"stock-high\""
            fi
        else
            row_class="class=\"row-inactive\""
        fi

        printf '        <tr %s>\n' "${row_class}"
        printf '            <td>%s</td>\n' "${i_ref[$i,id]}"
        printf '            <td>%s</td>\n' "${i_ref[$i,nombre]}"
        printf '            <td>%s</td>\n' "${i_ref[$i,categoria]}"
        printf '            <td>%s</td>\n' "${i_ref[$i,stock]}"
        printf '            <td>%s</td>\n' "${i_ref[$i,costo]}"
        printf '            <td>%s</td>\n' "${i_ref[$i,precio]}"
        printf '            <td>%s</td>\n' "${estado_texto}"
        printf '        </tr>\n'
    done
}

print_table_footer() {
    cat << 'EOF'

                        </tbody>
                    </table>
                </div>

                <!-- Web Component de Paginación -->
                <app-pagination page-size="10"></app-pagination>
            </div>

            <script>
                class AppPagination extends HTMLElement {
                    constructor() {
                        super();
                        this.attachShadow({ mode: 'open' });
                        this.currentPage = 1;
                        this.pageSize = parseInt(this.getAttribute('page-size')) || 10;
                        this.pageSizeOptions = [5, 10, 20, 50];
                    }

                    connectedCallback() {
                        // Esperar a que el DOM padre se renderice para calcular filas
                        setTimeout(() => {
                            this.tableBody = document.querySelector('tbody');
                            if (!this.tableBody) return;
                            this.allRows = Array.from(this.tableBody.querySelectorAll('tr'));
                            this.render();
                            this.updateTable();
                        }, 0);
                    }

                    get totalPages() {
                        return Math.ceil(this.allRows.length / this.pageSize) || 1;
                    }

                    updateTable() {
                        const start = (this.currentPage - 1) * this.pageSize;
                        const end = start + this.pageSize;

                        this.allRows.forEach((row, index) => {
                            if (index >= start && index < end) {
                                row.style.display = '';
                            } else {
                                row.style.display = 'none';
                            }
                        });

                        this.render();
                    }

                    changePage(newPage) {
                        if (newPage < 1 || newPage > this.totalPages) return;
                        this.currentPage = newPage;
                        this.updateTable();
                    }

                    changePageSize(newSize) {
                        this.pageSize = parseInt(newSize);
                        this.currentPage = 1;
                        this.updateTable();
                    }

                    render() {
                        if (this.allRows && this.allRows.length === 0) {
                            this.shadowRoot.innerHTML = '';
                            return;
                        }

                        this.shadowRoot.innerHTML = `
                            <style>
                                :host {
                                    display: block;
                                    margin-top: 20px;
                                }
                                .pagination-container {
                                    display: flex;
                                    flex-direction: column;
                                    align-items: center;
                                    justify-content: space-between;
                                    gap: 12px;
                                    background-color: #ffffff;
                                    border: 1px solid var(--border-color, #dfe6e9);
                                    border-radius: 10px;
                                    padding: 12px 16px;
                                    font-size: 0.85rem;
                                    color: #2d3436;
                                    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.03);
                                }
                                @media (min-width: 640px) {
                                    .pagination-container {
                                        flex-direction: row;
                                    }
                                }
                                .controls-group {
                                    display: flex;
                                    align-items: center;
                                    gap: 8px;
                                }
                                .label {
                                    font-size: 0.8rem;
                                    color: #636e72;
                                }
                                select {
                                    background-color: #f8f9fa;
                                    color: #2d3436;
                                    border: 1px solid #dfe6e9;
                                    border-radius: 6px;
                                    padding: 4px 8px;
                                    font-size: 0.8rem;
                                    outline: none;
                                    cursor: pointer;
                                    transition: border-color 0.2s;
                                }
                                select:focus {
                                    border-color: #6c5ce7;
                                }
                                button {
                                    padding: 6px 12px;
                                    background-color: #ffffff;
                                    border: 1px solid #dfe6e9;
                                    border-radius: 6px;
                                    color: #2d3436;
                                    font-size: 0.8rem;
                                    font-weight: 600;
                                    cursor: pointer;
                                    transition: all 0.2s;
                                }
                                button:hover:not(:disabled) {
                                    border-color: #6c5ce7;
                                    color: #6c5ce7;
                                    background-color: #f8f9fa;
                                }
                                button:disabled {
                                    opacity: 0.4;
                                    cursor: not-allowed;
                                }
                                .page-info {
                                    font-size: 0.8rem;
                                    color: #636e72;
                                }
                                .page-info strong {
                                    color: #2d3436;
                                }
                            </style>

                            <div class="pagination-container">
                                <div class="controls-group">
                                    <span class="label">Mostrar:</span>
                                    <select id="size-select">
                                        ${this.pageSizeOptions.map(opt => `
                                            <option value="${opt}" ${opt === this.pageSize ? 'selected' : ''}>
                                                ${opt} por página
                                            </option>
                                        `).join('')}
                                    </select>
                                </div>

                                <div class="controls-group">
                                    <button id="btn-prev" ${this.currentPage === 1 ? 'disabled' : ''}>
                                        Anterior
                                    </button>

                                    <span class="page-info">
                                        Página <strong>${this.currentPage}</strong> de <strong>${this.totalPages}</strong>
                                    </span>

                                    <button id="btn-next" ${this.currentPage === this.totalPages ? 'disabled' : ''}>
                                        Siguiente
                                    </button>
                                </div>
                            </div>
                        `;

                        // Event listeners
                        this.shadowRoot.querySelector('#size-select').addEventListener('change', (e) => {
                            this.changePageSize(e.target.value);
                        });

                        this.shadowRoot.querySelector('#btn-prev').addEventListener('click', () => {
                            this.changePage(this.currentPage - 1);
                        });

                        this.shadowRoot.querySelector('#btn-next').addEventListener('click', () => {
                            this.changePage(this.currentPage + 1);
                        });
                    }
                }

                customElements.define('app-pagination', AppPagination);
            </script>
        </body>
    </html>
EOF
}

generate_html() {
    local -n inv_ref=$1
    {
        print_table_headers
        print_table_body inv_ref
        print_table_footer
    } > "${HTML_VIEW_PATH}"

    if [ $? -eq 0 ]; then
        printf "Se ha generado el informe html correctamente.\n"
    else
        printf "No se ha podido generar el informe html.\n"
    fi
}



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

        stty sane
        read -rn 1 -p "Opcion: " action_option
        echo ""
        stty sane

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

                if declare -f commit_inventory_journal >/dev/null 2>&1; then
                    commit_inventory_journal inventory_global_array
                fi
                
                stty sane 2>/dev/null
                exit 0
                ;;
            *)
                printf "\nOpcion invalida.\n"
                ;;
        esac
    done

    return 0
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

    local option=0

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
#!/usr/bin/env bash

declare -A inventory_global_array=()
declare -i inventory_length=0

CONFIG_IMPORTS_PATH="./config.sh"

cleanup() {
    commit_inventory_journal inventory_global_array
    exit 0
}

main() {

    # Ctrl+C (SIGINT), terminal closing (SIGHUP), termination (SIGTERM)
    trap cleanup SIGINT SIGHUP SIGTERM

    trap 'stty sane 2>/dev/null' EXIT INT TERM

    welcome_message

    if ! get_option_from_user_and_execute_login_or_register; then
        return 1
    fi
  
    load_inventory_into_array inventory_global_array

    update_array_length_variable_by_ref inventory_global_array inventory_length

    get_option_from_user_and_execute_inventory_action inventory_global_array inventory_length

    return 0
}

main
