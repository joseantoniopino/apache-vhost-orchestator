#!/bin/bash

# Sistema de detección de motores de bases de datos
# Detecta los motores disponibles en el sistema

# Array para almacenar los motores de bases de datos disponibles
DB_ENGINES_AVAILABLE=()
DB_ENGINE=""

# Detectar bases de datos disponibles
detect_database_engines() {
    print_message "🔍 Detectando motores de bases de datos disponibles..." "$BLUE"

    # Verificar MySQL
    if command -v mysql &> /dev/null; then
        DB_ENGINES_AVAILABLE+=("mysql")
        print_message "   ✅ MySQL detectado" "$GREEN"
    fi

    # Verificar PostgreSQL
    if command -v psql &> /dev/null; then
        DB_ENGINES_AVAILABLE+=("postgresql")
        print_message "   ✅ PostgreSQL detectado" "$GREEN"
    fi

    # Verificar SQLite (siempre disponible si sqlite3 está instalado)
    if command -v sqlite3 &> /dev/null; then
        DB_ENGINES_AVAILABLE+=("sqlite")
        print_message "   ✅ SQLite detectado" "$GREEN"
    fi

    # Verificar SQL Server (mssql-tools o sqlcmd)
    if command -v sqlcmd &> /dev/null; then
        DB_ENGINES_AVAILABLE+=("sqlserver")
        print_message "   ✅ SQL Server detectado" "$GREEN"
    fi

    # Verificar MongoDB
    if command -v mongo &> /dev/null || command -v mongosh &> /dev/null; then
        DB_ENGINES_AVAILABLE+=("mongodb")
        print_message "   ✅ MongoDB detectado" "$GREEN"
    fi

    # Si no se detectó ningún motor, informar al usuario
    if [ ${#DB_ENGINES_AVAILABLE[@]} -eq 0 ]; then
        print_message "   ❌ No se detectaron motores de bases de datos compatibles" "$YELLOW"
        return 1
    fi

    print_message "   🔍 Total de motores detectados: ${#DB_ENGINES_AVAILABLE[@]}" "$BLUE"
    return 0
}

# Seleccionar motor de base de datos
select_database_engine() {
    # Si no hay motores disponibles, salir
    if [ ${#DB_ENGINES_AVAILABLE[@]} -eq 0 ]; then
        DB_ENGINE=""
        return 1
    fi

    # Si solo hay un motor disponible, usarlo por defecto
    if [ ${#DB_ENGINES_AVAILABLE[@]} -eq 1 ]; then
        DB_ENGINE="${DB_ENGINES_AVAILABLE[0]}"
        print_message "   ℹ️ Usando único motor disponible: $DB_ENGINE" "$BLUE"
        return 0
    fi

    # Mostrar opciones
    print_message "Selecciona el motor de base de datos a utilizar:" "$BLUE"
    select engine in "${DB_ENGINES_AVAILABLE[@]}" "Ninguno"; do
        if [ "$engine" = "Ninguno" ]; then
            DB_ENGINE=""
            print_message "   ℹ️ No se usará base de datos" "$BLUE"
            return 0
        elif [ -n "$engine" ]; then
            DB_ENGINE="$engine"
            print_message "   ✅ Motor seleccionado: $DB_ENGINE" "$GREEN"
            return 0
        else
            print_message "   ❌ Selección inválida, intenta de nuevo" "$RED"
        fi
    done
}