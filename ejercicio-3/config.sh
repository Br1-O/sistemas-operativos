
source "$(dirname "${BASH_SOURCE[0]}")/shared/utils/validations.sh"

load_persistence() {

    declare -a VALID_ENGINES=("tsv" "sqlite")
    declare PERSISTENCE_ENGINE="$1"

    if [[ ! " ${VALID_ENGINES[*]} " =~ " ${PERSISTENCE_ENGINE} " ]]; then
        if ! enum_field_with_validation "Seleccione el motor de persistencia" VALID_ENGINES PERSISTENCE_ENGINE "required"; then
            printf "Operación cancelada por el usuario.\n"
            exit 1
        fi
    fi
    
    if [[ "$PERSISTENCE_ENGINE" == "sqlite" ]]; then
        source "$(dirname "${BASH_SOURCE[0]}")/inventory/persistence/sqlite/inventory_sqlite.sh"
        source "$(dirname "${BASH_SOURCE[0]}")/user/persistence/sqlite/users_sqlite.sh"
    else
        source "$(dirname "${BASH_SOURCE[0]}")/inventory/persistence/tsv/inventory_tsv.sh"
        source "$(dirname "${BASH_SOURCE[0]}")/user/persistence/tsv/users_tsv.sh"
    fi

    printf "Usando motor de persistencia %s .\n" "${PERSISTENCE_ENGINE}"
}

load_persistence $1

load_modules(){
    local target_dir="$1"

    for module in "${target_dir}"/*.sh; do

        if [[ -f "$module" ]]; then
            source "$module"
        else
            echo "No se encontró el módulo $module" >&2
        fi

    done
}

load_modules "./inventory/use_cases" 
load_modules "./inventory/ui" 
load_modules "./shared/utils" 
load_modules "./user/use_cases" 
load_modules "./user/ui" 