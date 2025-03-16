#!/bin/bash

# Función mejorada para crear bases de datos
create_database_enhanced() {
    local project_name=$1
    local project_path=$2
    local domain=$3
    local framework=$4

    # Cargar scripts necesarios
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/detect.sh"

    # Preguntar si el usuario quiere crear una base de datos
    read -p "¿Quieres crear una base de datos para este proyecto? (s/n): " create_db
    if [[ $create_db != "s" && $create_db != "S" ]]; then
        return 0
    fi

    # Detectar motores disponibles
    detect_database_engines

    # Seleccionar motor
    select_database_engine

    # Si no se seleccionó un motor, salir
    if [ -z "$DB_ENGINE" ]; then
        print_message "   ℹ️ No se creará base de datos" "$BLUE"
        return 0
    fi

    # Cargar el motor específico
    source "$SCRIPT_DIR/engines/${DB_ENGINE}.sh"

    # Variables para almacenar la configuración resultante
    local db_config=""

    # Llamar a la función específica del motor
    case "$DB_ENGINE" in
        "mysql")
            db_config=$(create_mysql_db "$project_name")
            ;;
        "postgresql")
            db_config=$(create_postgresql_db "$project_name")
            ;;
        "sqlite")
            db_config=$(create_sqlite_db "$project_name" "$project_path")
            ;;
        "sqlserver")
            db_config=$(create_sqlserver_db "$project_name")
            ;;
        "mongodb")
            db_config=$(create_mongodb_db "$project_name")
            ;;
        *)
            print_message "   ❌ Motor no soportado: $DB_ENGINE" "$RED"
            return 1
            ;;
    esac

    # Si la creación falló, salir
    if [ $? -ne 0 ]; then
        print_message "   ❌ Error al crear la base de datos" "$RED"
        return 1
    fi

    # Configurar framework si es necesario
    if [ "$framework" == "laravel" ]; then
        # Para Laravel, extraer los parámetros y configurar el .env
        print_message "   Configurando Laravel para usar $DB_ENGINE..." "$BLUE"

        # Extraer variables de la configuración
        local db_host=$(echo "$db_config" | grep "DB_HOST" | cut -d= -f2)
        local db_port=$(echo "$db_config" | grep "DB_PORT" | cut -d= -f2)
        local db_name=$(echo "$db_config" | grep "DB_DATABASE" | cut -d= -f2)
        local db_user=$(echo "$db_config" | grep "DB_USERNAME" | cut -d= -f2)
        local db_pass=$(echo "$db_config" | grep "DB_PASSWORD" | cut -d= -f2)

        # Asegurarse de que laravel.sh esté cargado
        source "$PROJECT_ROOT/modules/framework-detection/laravel.sh"

        # Llamar a la función en laravel.sh
        configure_laravel_db_env "$project_path" "$DB_ENGINE" "$db_name" "$db_user" "$db_pass" "$db_host" "$db_port" "$db_name"
    else
        # Para otros frameworks o proyectos genéricos, solo mostrar información
        print_message "   ✅ Base de datos creada. Credenciales:" "$GREEN"
        echo "$db_config" | while IFS='=' read -r key value; do
            print_message "   $key: $value" "$BLUE"
        done
    fi

    return 0
}