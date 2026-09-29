#!/usr/bin/env bash

#▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ Constants for DB ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀#

db_init(){

    readonly SQL="sqlite3"

    readonly INV_DB="datos_inventario.db"
    local readonly GENERATE_INVENTORY_TABLE_QUERY="
        PRAGMA foreign_keys = ON;

        CREATE TABLE IF NOT EXISTS Categories(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL CHECK (length(name) <= 50),
        description TEXT NOT NULL CHECK (length(description) <= 100)
        );

        CREATE TABLE IF NOT EXISTS Inventory(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL CHECK (length(name) <= 50),
        category_id INTEGER NOT NULL,
        stock INTEGER,
        cost REAL,
        price REAL,
        active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
        FOREIGN KEY category_id REFERENCES Categories(id)
        );

        CREATE TABLE IF NOT EXISTS Users(
        id INTEGER PRIMARY KEY,
        username TEXT NOT NULL CHECK (length(username) <= 50),
        password TEXT NOT NULL CHECK (length(password) <= 50)
        );
    "
    generate -r GENERATE_INVENTORY_TABLE="${SQL}" "${INV_DB}" "${GENERATE_INVENTORY_TABLE_QUERY}"
    GENERATE_INVENTORY_TABLE

    local readonly USERS_DB="datos_usuarios.db"
    local readonly GENERATE_USERS_TABLE_QUERY="
        CREATE TABLE IF NOT EXISTS Users(
        id INTEGER PRIMARY KEY,
        username TEXT NOT NULL CHECK (length(username) <= 50),
        password TEXT NOT NULL CHECK (length(password) <= 50)
    );
    "
    generate -r GENERATE_USERS_TABLE="${SQL}" "${USERS_DB}" "${GENERATE_USERS_TABLE_QUERY}"
    GENERATE_USERS_TABLE
}



readonly GET_ALL_INV="SELECT 
i.id,
i.name,
c.name as category,
i.stock,
i.cost,
i.price,
i.active
FROM Inventory i
INNER JOIN Categories c
ON i.category_id = c.id;"

readonly GET_ALL_INV_ACTIVE="${GET_ALL_INV} WHERE active=1;"
readonly GET_INV_ONE="${GET_ALL_INV} WHERE id=${product_id};"

