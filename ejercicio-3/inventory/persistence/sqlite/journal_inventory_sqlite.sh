
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