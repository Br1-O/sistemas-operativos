#!/usr/bin/env bash

HTML_VIEW_PATH="data/vista_inventario.html"

print_table_headers() {
    cat << EOF > "${HTML_VIEW_PATH}"
    
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
                --inactive-bg: #fde8e8;
                --inactive-text: #c0392b;
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

            /* Estilo específico para filas de productos NO DISPONIBLES */
            tbody tr.row-inactive {
                background-color: var(--inactive-bg) !important;
                color: var(--inactive-text);
            }

            tbody tr.row-inactive:hover {
                background-color: #fabbbb !important;
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
        local estado_texto="no disponible"
        local row_class=""

        if [[ "${i_ref[$i,activo]}" == "1" ]]; then
            estado_texto="disponible"
        else
            row_class="class=\"row-inactive\""
        fi

        cat << EOF >> "${HTML_VIEW_PATH}"
        <tr ${row_class}>
            <td> ${i_ref[$i,id]} </td>
            <td> ${i_ref[$i,nombre]} </td>
            <td> ${i_ref[$i,categoria]} </td>
            <td> ${i_ref[$i,stock]} </td>
            <td> ${i_ref[$i,costo]} </td>
            <td> ${i_ref[$i,precio]} </td>
            <td> ${estado_texto} </td>
        </tr>
EOF
    done
}

print_table_footer() {
    cat << EOF >> "${HTML_VIEW_PATH}"

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

    print_table_headers
    print_table_body inv_ref
    print_table_footer
}