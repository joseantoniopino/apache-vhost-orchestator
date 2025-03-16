#!/bin/bash

# Función mejorada para limpiar bases de datos
clean_database_enhanced() {
    local project_name=$1
    local project_path=$2

    # Cargar scripts necesarios
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/detect.sh"

    # Detectar motores disponibles
    detect_database_engines

    print_message "🔄 Verificando bases de datos para limpiar..." "$BLUE"

    # Si no hay motores disponibles, salir
    if [ ${#DB_ENGINES_AVAILABLE[@]} -eq 0 ]; then
        print_message "   ℹ️ No se detectaron motores de bases de datos" "$BLUE"
        return 0
    fi

    # Para cada motor disponible, preguntar si se debe limpiar
    for engine in "${DB_ENGINES_AVAILABLE[@]}"; do
        print_message "¿Quieres verificar y limpiar bases de datos de $engine? (s/n): " "$YELLOW"
        read -p "> " clean_this_engine

        if [[ $clean_this_engine == "s" || $clean_this_engine == "S" ]]; then
            # Cargar el módulo específico del motor
            source "$SCRIPT_DIR/engines/${engine}.sh"

            # Llamar a la función de limpieza
            case "$engine" in
                "mysql")
                    clean_mysql_db "$project_name"
                    ;;
                "postgresql")
                    clean_postgresql_db "$project_name"
                    ;;
                "sqlite")
                    clean_sqlite_db "$project_name" "$project_path"
                    ;;
                "sqlserver")
                    clean_sqlserver_db "$project_name"
                    ;;
                "mongodb")
                    clean_mongodb_db "$project_name"
                    ;;
                *)
                    print_message "   ❌ Limpieza no implementada para $engine" "$RED"
                    ;;
            esac
        fi
    done

    print_message "✅ Proceso de limpieza de bases de datos completado." "$GREEN"
    return 0
}