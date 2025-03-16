#!/bin/bash

# Función específica para crear base de datos PostgreSQL
create_postgresql_db() {
    local project_name=$1

    # Normalizar nombre del proyecto para PostgreSQL (sin guiones, convertir a minúsculas)
    local db_name=$(echo "${project_name}" | tr '-' '_' | tr '[:upper:]' '[:lower:]')
    local db_user="${db_name}_user"
    local db_pass="password123"  # Contraseña simple para desarrollo

    print_message "🗄️ Creando base de datos PostgreSQL: $db_name" "$BLUE"

    # Verificar si podemos conectar como usuario postgres
    if ! sudo -u postgres psql -c "\l" &>/dev/null; then
        print_message "   ❌ No se puede conectar a PostgreSQL. Verifica que el servicio esté corriendo y el usuario postgres exista." "$RED"
        return 1
    fi

    # Crear usuario
    print_message "   Creando usuario $db_user..." "$BLUE"
    if sudo -u postgres psql -c "DROP ROLE IF EXISTS $db_user;" &>/dev/null && \
       sudo -u postgres psql -c "CREATE USER $db_user WITH PASSWORD '$db_pass';" &>/dev/null; then
        print_message "   ✅ Usuario creado correctamente" "$GREEN"
    else
        print_message "   ❌ Error al crear usuario" "$RED"
        return 1
    fi

    # Crear base de datos
    print_message "   Creando base de datos $db_name..." "$BLUE"
    if sudo -u postgres psql -c "DROP DATABASE IF EXISTS $db_name;" &>/dev/null && \
       sudo -u postgres psql -c "CREATE DATABASE $db_name OWNER $db_user;" &>/dev/null; then
        print_message "   ✅ Base de datos creada correctamente" "$GREEN"

        # Otorgar privilegios adicionales
        sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;" &>/dev/null

        print_message "   ✅ Privilegios asignados correctamente" "$GREEN"

        # Devolver configuración
        echo "DB_CONNECTION=pgsql"
        echo "DB_HOST=127.0.0.1"
        echo "DB_PORT=5432"
        echo "DB_DATABASE=$db_name"
        echo "DB_USERNAME=$db_user"
        echo "DB_PASSWORD=$db_pass"

        return 0
    else
        print_message "   ❌ Error al crear la base de datos" "$RED"
        # Intentar limpiar el usuario creado si la base de datos falla
        sudo -u postgres psql -c "DROP ROLE IF EXISTS $db_user;" &>/dev/null
        return 1
    fi
}

# Función para limpiar bases de datos PostgreSQL
clean_postgresql_db() {
    local project_name=$1

    # Normalizar nombre del proyecto
    local db_name=$(echo "${project_name}" | tr '-' '_' | tr '[:upper:]' '[:lower:]')
    local db_user="${db_name}_user"

    print_message "🔄 Limpiando base de datos PostgreSQL para $project_name..." "$BLUE"

    # Verificar conexión
    if ! sudo -u postgres psql -c "\l" &>/dev/null; then
        print_message "   ❌ No se puede conectar a PostgreSQL. Verifica que el servicio esté corriendo." "$RED"
        return 1
    fi

    # Verificar si la base de datos existe
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
        print_message "   ¿Eliminar base de datos: $db_name? (s/n)" "$YELLOW"
        read -p "> " confirm_delete_db

        if [[ $confirm_delete_db == "s" || $confirm_delete_db == "S" ]]; then
            print_message "   Eliminando base de datos: $db_name" "$BLUE"
            # Cerrar conexiones activas antes de eliminar
            sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$db_name';" &>/dev/null
            if sudo -u postgres psql -c "DROP DATABASE $db_name;" &>/dev/null; then
                print_message "   ✅ Base de datos eliminada" "$GREEN"
            else
                print_message "   ❌ No se pudo eliminar la base de datos" "$RED"
            fi
        else
            print_message "   Se omite la eliminación de la base de datos $db_name" "$YELLOW"
        fi
    else
        print_message "   Base de datos no encontrada: $db_name" "$YELLOW"
    fi

    # Verificar si el usuario existe
    if sudo -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname='$db_user';" | grep -q 1; then
        print_message "   Eliminando usuario PostgreSQL: $db_user" "$BLUE"
        if sudo -u postgres psql -c "DROP ROLE IF EXISTS $db_user;" &>/dev/null; then
            print_message "   ✅ Usuario eliminado" "$GREEN"
        else
            print_message "   ❌ No se pudo eliminar el usuario. Puede que tenga objetos asignados." "$RED"
        fi
    else
        print_message "   Usuario PostgreSQL no encontrado: $db_user" "$YELLOW"
    fi

    print_message "✅ Limpieza de PostgreSQL completada." "$GREEN"

    return 0
}