#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/journal_inventory_sqlite.sh"

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