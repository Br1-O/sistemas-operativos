
SQLITE_USERS_PATH="shared/data/datos_usuarios.db"

init_users_storage() {
    mkdir -p "$(dirname "$SQLITE_USERS_PATH")"
    sqlite3 "$SQLITE_USERS_PATH" <<EOF
CREATE TABLE IF NOT EXISTS Users (
    id INTEGER PRIMARY KEY,
    username TEXT UNIQUE NOT NULL CHECK (length(username) <= 50),
    password TEXT NOT NULL CHECK (length(password) <= 100)
);
EOF
}

hash_password() {
    local password_value="$1"
    local -n _out_hash_ref=$2

    read -r _out_hash_ref _ < <(printf '%s' "${password_value}" | sha256sum)
}

save_user() {
    local username="$1"
    local password="$2"
    local hashed_password=""

    hash_password "$password" hashed_password

    init_users_storage
    local safe_username="${username//\'/\'\'}"
    sqlite3 "$SQLITE_USERS_PATH" "INSERT INTO Users (username, password) VALUES ('$safe_username', '$hashed_password');" 2>/dev/null
    return $?
}

username_exists() {
    local entered_username="$1"

    if [[ ! -f "$SQLITE_USERS_PATH" ]]; then
        return 2
    fi

    local safe_username="${entered_username//\'/\'\'}"
    local count=0
    read -r count < <(sqlite3 "$SQLITE_USERS_PATH" "SELECT COUNT(*) FROM Users WHERE username='$safe_username';")

    if (( count > 0 )); then
        return 0
    else
        return 1
    fi
}

find_hashed_password_by_username() {
    local entered_username="$1"
    local -n _out_pass_ref=$2

    if [[ ! -f "$SQLITE_USERS_PATH" ]]; then
        return 1
    fi

    local safe_username="${entered_username//\'/\'\'}"
    _out_pass_ref=""
    read -r _out_pass_ref < <(sqlite3 "$SQLITE_USERS_PATH" "SELECT password FROM Users WHERE username='$safe_username';")

    if [[ -n "$_out_pass_ref" ]]; then
        return 0
    fi

    return 1
}

password_is_correct() {
    local entered_username="$1"
    local entered_password="$2"
    local db_password=""
    local input_hash=""

    if ! find_hashed_password_by_username "${entered_username}" db_password; then
        return 1
    fi

    hash_password "${entered_password}" input_hash

    if [[ "${input_hash}" == "${db_password}" ]]; then
        return 0
    fi

    return 1
}