#!/bin/bash

# Función específica para crear base de datos SQLite
create_sqlite_db() {
    local project_name=$1
    local project_path=$2

    # Crear directorio de base de datos
    local db_dir="$project_path/database"
    local db_file="$db_dir/$project_name.sqlite"

    print_message "🗄️ Creando base de datos SQLite: $db_file" "$BLUE"

    # Crear directorio si no existe
    if [ ! -d "$db_dir" ]; then
        mkdir -p "$db_dir"
        chmod 755 "$db_dir"
        chown "$REAL_USER":"$REAL_USER" "$db_dir"
    fi

    # Crear archivo vacío
    touch "$db_file"
    chmod 644 "$db_file"
    chown "$REAL_USER":"$REAL_USER" "$db_file"

    # Verificar creación exitosa
    if [ ! -f "$db_file" ]; then
        print_message "   ❌ Error al crear archivo de base de datos" "$RED"
        return 1
    fi

    print_message "   ✅ Archivo de base de datos SQLite creado" "$GREEN"

    # Devolver configuración
    echo "DB_CONNECTION=sqlite"
    echo "DB_DATABASE=$db_file"

    return 0
}

# Función para limpiar bases de datos SQLite
clean_sqlite_db() {
    local project_name=$1
    local project_path=$2

    print_message "🔄 Limpiando base de datos SQLite para $project_name..." "$BLUE"

    # Posibles ubicaciones del archivo de base de datos
    local possible_paths=(
        "$project_path/database/$project_name.sqlite"
        "$project_path/$project_name.sqlite"
        # Agregar otras ubicaciones posibles si es necesario
    )

    local found=0

    # Buscar y eliminar archivos de base de datos
    for db_path in "${possible_paths[@]}"; do
        if [ -f "$db_path" ]; then
            print_message "   Encontrado archivo de base de datos: $db_path" "$BLUE"
            print_message "   ¿Eliminar este archivo? (s/n)" "$YELLOW"
            read -p "> " confirm_delete

            if [[ $confirm_delete == "s" || $confirm_delete == "S" ]]; then
                rm -f "$db_path"
                print_message "   ✅ Archivo de base de datos eliminado" "$GREEN"
                found=1
            else
                print_message "   Se omite la eliminación del archivo" "$YELLOW"
            fi
        fi
    done

    if [ $found -eq 0 ]; then
        print_message "   No se encontraron archivos de base de datos SQLite para $project_name" "$YELLOW"
    fi

    print_message "✅ Limpieza de SQLite completada." "$GREEN"

    return 0
}