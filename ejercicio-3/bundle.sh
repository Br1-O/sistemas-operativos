#!/usr/bin/env bash

PERSISTENCE="${1:-sqlite}"
OUTPUT_FILE="ejercicio-3-standalone-${PERSISTENCE}.sh"

echo "#!/usr/bin/env bash" > "$OUTPUT_FILE"
echo "# Generado automáticamente ($PERSISTENCE)" >> "$OUTPUT_FILE"

# Función auxiliar para concatenar filtrando sentencias 'source' o '.'
append_clean() {
    for file in "$@"; do
        if [[ -f "$file" ]]; then
            # Elimina líneas que inicien con 'source' o '.' (manejando espacios previos)
            sed -E '/^[[:space:]]*(source|\.)[[:space:]]+/d' "$file" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        fi
    done
}

# 1. Inclusión de Utilidades
append_clean shared/utils/helpers.sh shared/utils/validations.sh

# 2. Inclusión de Persistencia (SQLite o TSV)
if [[ "$PERSISTENCE" == "sqlite" ]]; then
    append_clean inventory/persistence/sqlite/inventory_sqlite.sh \
                 inventory/persistence/sqlite/journal_inventory_sqlite.sh \
                 user/persistence/sqlite/users_sqlite.sh
else
    append_clean inventory/persistence/tsv/inventory_tsv.sh \
                 inventory/persistence/tsv/journal_inventory_tsv.sh \
                 user/persistence/tsv/users_tsv.sh
fi

# 3. Inclusión de Casos de Uso y UI
append_clean inventory/use_cases/use_cases_inventory.sh \
             user/use_cases/use_cases_users.sh \
             inventory/ui/html_generator_inventory.sh \
             inventory/ui/menues.sh \
             user/ui/menues.sh

# 4. Inclusión de Config y Main
append_clean ejercicio-3.sh

# Otorgar permisos de ejecución al ejecutable final
chmod +x "$OUTPUT_FILE"

echo "Bundle generado exitosamente ($PERSISTENCE) en $OUTPUT_FILE"