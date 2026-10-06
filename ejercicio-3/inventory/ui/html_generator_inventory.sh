#!/usr/bin/env bash

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
    cat << EOF

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