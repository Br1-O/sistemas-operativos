#!/usr/bin/env bash

PERSISTENCE="${1:-sqlite}"
OUTPUT_FILE="ejercicio-3-standalone-${PERSISTENCE}.sh"

echo "#!/usr/bin/env bash" > "$OUTPUT_FILE"
echo "# Generado automáticamente ($PERSISTENCE)" >> "$OUTPUT_FILE"

append_clean() {
    for file in "$@"; do
        if [[ -f "$file" ]]; then
            sed -E '/^[[:space:]]*(source|\.)[[:space:]]+/d' "$file" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        fi
    done
}

append_clean shared/utils/helpers.sh shared/utils/validations.sh shared/utils/nc_http_server.sh

if [[ "$PERSISTENCE" == "sqlite" ]]; then
    append_clean inventory/persistence/sqlite/inventory_sqlite.sh \
                 inventory/persistence/sqlite/journal_inventory_sqlite.sh \
                 user/persistence/sqlite/users_sqlite.sh
else
    append_clean inventory/persistence/tsv/inventory_tsv.sh \
                 inventory/persistence/tsv/journal_inventory_tsv.sh \
                 user/persistence/tsv/users_tsv.sh
fi

append_clean inventory/use_cases/use_cases_inventory.sh \
             user/use_cases/use_cases_users.sh \
             inventory/ui/html_generator_inventory.sh \
             inventory/ui/menues.sh \
             user/ui/menues.sh

append_clean ejercicio-3.sh

chmod +x "$OUTPUT_FILE"

echo "Bundle generado exitosamente ($PERSISTENCE) en $OUTPUT_FILE"