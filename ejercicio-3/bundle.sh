#!/usr/bin/env bash
# bundle.sh - Genera un archivo unificado bundle.sh

OUTPUT_FILE="ejercicio-3-standalone.sh"

echo "#!/usr/bin/env bash" > "$OUTPUT_FILE"
echo "# Generado automáticamente" >> "$OUTPUT_FILE"

# 1. Incluir Utils
cat utils/helpers.sh utils/validations.sh >> "$OUTPUT_FILE"

# 2. Incluir Persistence (SQLite o TSV)
cat persistence/sqlite/inventory_sqlite.sh persistence/sqlite/users_sqlite.sh >> "$OUTPUT_FILE"

# 3. Incluir Use Cases y UI
cat use_cases/use_cases_inventory.sh use_cases/use_cases_users.sh >> "$OUTPUT_FILE"
cat ui/html_generator_inventory.sh ui/menues.sh >> "$OUTPUT_FILE"

# 4. Incluir Config y Main
cat config.sh ejercicio-3.sh >> "$OUTPUT_FILE"

chmod +x "$OUTPUT_FILE"
echo "Archivo unificado generado en $OUTPUT_FILE"