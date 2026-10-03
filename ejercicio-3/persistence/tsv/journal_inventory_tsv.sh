#!/usr/bin/env bash

#Init a new tsv file with the columns names passed as an array via columns_ref
journal_init_storage() {
    local tsv_path="$1"
    local -n columns_ref=$2

    if [[ ! -f "$tsv_path" ]]; then
        mkdir -p "$(dirname "$tsv_path")"
        local header
        IFS=$'\t' eval 'header="${columns_ref[*]}"'
        echo -e "$header" > "$tsv_path"
    fi
}

#Load the data from a tsv file into the array in memory
journal_load_to_assoc_array() {
    local tsv_path="$1"
    local -n target_array_ref=$2
    local -n columns_ref=$3

    [[ ! -f "$tsv_path" ]] && return 1

    local line_num=0
    while IFS=$'\t' read -r -a row_data; do

        ((line_num == 0)) && { ((line_num++)); continue; }
        [[ -z "${row_data[0]}" ]] && continue

        local primary_id="${row_data[0]}"
        for idx in "${!columns_ref[@]}"; do
            local col_name="${columns_ref[$idx]}"
            target_array_ref["${primary_id},${col_name}"]="${row_data[$idx]}"
        done
        ((line_num++))
    done < "$tsv_path"
}

#Writes a new log into the wal action log, to ensure that it processes on any kind of closing of the app
journal_append_log() {
    local journal_path="$1"
    local user="$2"
    local action="$3" # INSERT, UPDATE, DELETE
    shift 3
    local record_data=("$@")

    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local state="PENDING"
    local payload
    IFS=$'\t' eval 'payload="${record_data[*]}"'

    printf "%s\t%s\t%s\t%s\t%s\n" "$timestamp" "$user" "$action" "$payload" "$state" >> "$journal_path"
}

#Applies the changes from the wal log into the array in memory
journal_wal_recover_and_apply() {
    local journal_path="$1"
    local -n target_array_ref=$2
    local -n columns_ref=$3

    [[ ! -f "$journal_path" ]] && return 0

    local tmp_journal="${journal_path}.tmp"
    > "$tmp_journal"

    while IFS=$'\t' read -r timestamp user action payload state; do
        [[ -z "$action" ]] && continue

        if [[ "$state" == "PENDING" ]]; then
            IFS=$'\t' read -r -a fields <<< "$payload"
            local primary_id="${fields[0]}"

            case "$action" in
                INSERT|UPDATE)
                    for idx in "${!columns_ref[@]}"; do
                        local col_name="${columns_ref[$idx]}"
                        target_array_ref["${primary_id},${col_name}"]="${fields[$idx]}"
                    done
                    ;;
                DELETE)
                    target_array_ref["${primary_id},activo"]=0
                    ;;
            esac
            state="DONE"
        fi

        printf "%s\t%s\t%s\t%s\t%s\n" "$timestamp" "$user" "$action" "$payload" "$state" >> "$tmp_journal"
    done < "$journal_path"

    [[ -s "$tmp_journal" ]] && mv "$tmp_journal" "$journal_path"
}

#Saves the in memory array into the data tsv file, and empties the wal log
journal_checkpoint() {
    local tsv_path="$1"
    local journal_path="$2"
    local -n target_array_ref=$3
    local -n columns_ref=$4
    local -i max_records=$5

    local header
    IFS=$'\t' eval 'header="${columns_ref[*]}"'
    echo -e "$header" > "${tsv_path}.tmp"

    for ((i=0; i<max_records; i++)); do
        if [[ -n "${target_array_ref[$i,id]}" ]]; then
            local row=()
            for col_name in "${columns_ref[@]}"; do
                row+=("${target_array_ref[$i,$col_name]}")
            done
            local line
            IFS=$'\t' eval 'line="${row[*]}"'
            echo -e "$line" >> "${tsv_path}.tmp"
        fi
    done

    if [[ -f "$tsv_path.tmp" ]]; then

        mv "$tsv_path.tmp" "$tsv_path"

        #write and keep the last 100 logs
        if [[ -f "$journal_path" ]]; then

            local tmp_journal="${journal_path}.tmp"
            local tmp_journal_tail="${journal_path}.tail.tmp"
            > "$tmp_journal"

            while IFS=$'\t' read -r timestamp user action remainder; do
                [[ -z "$action" ]] && continue

                local payload_clean="${remainder%$'\t'*}"

                printf "%s\t%s\t%s\t%s\tDONE\n" "$timestamp" "$user" "$action" "$payload_clean" >> "$tmp_journal"
            done < "$journal_path"

            tail -n 100 "$tmp_journal" > "$tmp_journal_tail" && mv "$tmp_journal_tail" "$journal_path"
            rm -f "$tmp_journal"
        fi
    fi
}