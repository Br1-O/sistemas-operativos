#!/usr/bin/env bash

source "./utils/wal_engine.sh"

TSV_INVENTORY_PATH="data/datos_inventario.tsv"
JOURNAL_INVENTORY_PATH="data/datos_inventario.journal"

#Dinamic schema for columns
INVENTORY_COLUMNS=("id" "nombre" "categoria" "stock" "costo" "precio" "activo")

load_inventory_into_array() {
    local -n invent_ref=$1

    #Init tsv file
    init_tsv_schema "$TSV_INVENTORY_PATH" INVENTORY_COLUMNS

    #Load tsv data into array
    load_tsv_to_assoc_array "$TSV_INVENTORY_PATH" invent_ref INVENTORY_COLUMNS

    if [[ -s "$JOURNAL_INVENTORY_PATH" ]]; then
       #Load wal data into array if there are pending
        wal_recover_and_apply "$JOURNAL_INVENTORY_PATH" invent_ref INVENTORY_COLUMNS
        
        #Writes the in memory array into the tsv file
        flush_inventory_wal invent_ref
    fi
}

#Writes a new entry into the wal log
save_product_wal() {
    local action="$1" # INSERT, UPDATE o DELETE
    local -n prod_ref=$2

    local row=()
    for col in "${INVENTORY_COLUMNS[@]}"; do
        row+=("${prod_ref[$col]}")
    done

    wal_append_log "$JOURNAL_INVENTORY_PATH" "$action" "${row[@]}"
}

#Saves the in memory array into the tsv data file
flush_inventory_wal() {
    local -n invent_ref=$1
    wal_checkpoint "$TSV_INVENTORY_PATH" "$JOURNAL_INVENTORY_PATH" invent_ref INVENTORY_COLUMNS MAX
}