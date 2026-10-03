#!/usr/bin/env bash

SQLITE_USERS_PATH="data/datos_usuarios.db"

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
    local password="$1"
    printf "%s" "${password}" | sha256sum | awk '{print $1}'
}

save_user() {
    local username="$1"
    local hashed_password="$(hash_password "$2")"

    init_users_storage
    sqlite3 "$SQLITE_USERS_PATH" "INSERT INTO Users (username, password) VALUES ('$username', '$hashed_password');" 2>/dev/null
    return $?
}

username_exists() {
    local entered_username="$1"

    if [[ ! -f "$SQLITE_USERS_PATH" ]]; then
        return 2
    fi

    local count
    count=$(sqlite3 "$SQLITE_USERS_PATH" "SELECT COUNT(*) FROM Users WHERE username='$entered_username';")

    if [[ "$count" -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

find_hashed_password_by_username() {
    local entered_username="$1"

    if [[ ! -f "$SQLITE_USERS_PATH" ]]; then
        return 1
    fi

    local saved_pass
    saved_pass=$(sqlite3 "$SQLITE_USERS_PATH" "SELECT password FROM Users WHERE username='$entered_username';")

    if [[ -n "$saved_pass" ]]; then
        printf "%s" "$saved_pass"
        return 0
    fi

    return 1
}

password_is_correct() {
    local entered_username="$1"
    local entered_password="$(hash_password "$2")"
    local saved_password="$(find_hashed_password_by_username "${entered_username}")"

    if [[ -z "${saved_password}" ]]; then
        return 1
    fi

    if [[ "${entered_password}" == "${saved_password}" ]]; then
        return 0
    else
        return 1
    fi
}