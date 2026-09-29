#!/usr/bin/env bash

clear_screen() {
    # 1. Intenta usar el comando ejecutable nativo del sistema
    if command -v clear >/dev/null 2>&1; then
        clear
    # 2. Respaldo para Windows nativo (CMD / PowerShell dentro de Git Bash)
    elif command -v cls >/dev/null 2>&1; then
        cls
    # 3. Respaldo universal por código de escape ANSI (funciona en casi cualquier emulador de terminal)
    else
        printf "\033[c\033[2J\033[H"
    fi
}