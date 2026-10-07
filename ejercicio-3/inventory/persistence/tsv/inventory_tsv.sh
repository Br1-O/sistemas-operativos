
source "$(dirname "${BASH_SOURCE[0]}")/journal_inventory_tsv.sh"

TSV_INVENTORY_PATH="shared/data/datos_inventario.tsv"
JOURNAL_INVENTORY_PATH="shared/data/datos_inventario.journal"

#Dinamic schema for columns
INVENTORY_COLUMNS=("id" "nombre" "categoria" "stock" "costo" "precio" "activo")

CURRENT_USER="${CURRENT_USER:-sistema}"

load_inventory_into_array() {
    local -n invent_reference=$1

    #Init storage file
    journal_init_storage "$TSV_INVENTORY_PATH" INVENTORY_COLUMNS

    #Load storage data into array
    journal_load_to_assoc_array "$TSV_INVENTORY_PATH" invent_reference INVENTORY_COLUMNS

    if [[ -s "$JOURNAL_INVENTORY_PATH" ]]; then
       #Load wal data into array if there are pending
        journal_wal_recover_and_apply "$JOURNAL_INVENTORY_PATH" invent_reference INVENTORY_COLUMNS
        
        #Writes the in memory array into the tsv file
        commit_inventory_journal invent_reference
    fi
}

#Writes a new entry into the wal log
save_product_action_to_journal() {
    local action="$1" # INSERT, UPDATE o DELETE
    local -n prod_reference=$2

    local row=()
    for col in "${INVENTORY_COLUMNS[@]}"; do
        row+=("${prod_reference[$col]}")
    done

    journal_append_log "$JOURNAL_INVENTORY_PATH" "$CURRENT_USER" "$action" "${row[@]}"
}

#Saves the in memory array into the tsv data file
commit_inventory_journal() {
    local -n inventory_ref=$1
    journal_checkpoint "$TSV_INVENTORY_PATH" "$JOURNAL_INVENTORY_PATH" inventory_ref INVENTORY_COLUMNS
}