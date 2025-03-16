#!/bin/bash

# Función específica para crear base de datos MySQL
create_mysql_db() {
    local project_name=$1

    # Usar nombre del proyecto como nombre de base de datos
    local db_name="${project_name}"
    local db_user="${project_name}_user"
    local db_pass="password123"  # Contraseña simple para desarrollo

    print_message "🗄️ Creando base de datos MySQL: $db_name" "$BLUE"

    # Solicitar credenciales de root
    local mysql_root_pass=""
    local mysql_cmd="mysql"

    # Verificar si necesitamos contraseña
    if ! mysql -u root -e "SELECT 1" &>/dev/null; then
        read -sp "Introduce la contraseña de root para MySQL: " mysql_root_pass
        echo ""

        # Probar contraseña
        if ! mysql -u root -p"$mysql_root_pass" -e "SELECT 1" &>/dev/null; then
            print_message "   ❌ Contraseña incorrecta" "$RED"
            return 1
        fi

        mysql_cmd="mysql -u root -p\"$mysql_root_pass\""
    fi

    # Crear base de datos
    if ! eval "$mysql_cmd -e \"CREATE DATABASE IF NOT EXISTS \\\`$db_name\\\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\""; then
        print_message "   ❌ Error al crear la base de datos" "$RED"
        return 1
    fi

    # Crear usuario y asignar permisos
    eval "$mysql_cmd -e \"DROP USER IF EXISTS '$db_user'@'localhost';\""
    eval "$mysql_cmd -e \"CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';\""
    eval "$mysql_cmd -e \"GRANT ALL PRIVILEGES ON \\\`$db_name\\\`.* TO '$db_user'@'localhost';\""
    eval "$mysql_cmd -e \"FLUSH PRIVILEGES;\""

    print_message "   ✅ Base de datos y usuario creados correctamente" "$GREEN"

    # Devolver configuración en formato clave=valor
    echo "DB_CONNECTION=mysql"
    echo "DB_HOST=127.0.0.1"
    echo "DB_PORT=3306"
    echo "DB_DATABASE=$db_name"
    echo "DB_USERNAME=$db_user"
    echo "DB_PASSWORD=$db_pass"

    return 0
}

# Función para limpiar bases de datos MySQL
clean_mysql_db() {
    local project_name=$1

    # Nombres de la base de datos y usuario
    local db_name="$project_name"
    local db_user="${project_name}_user"

    print_message "🔄 Limpiando base de datos MySQL para $project_name..." "$BLUE"

    # Pedir contraseña de root de MySQL
    read -sp "Introduce la contraseña de root de MySQL (deja vacío si no hay): " mysql_pwd
    echo ""

    # Configurar comando de MySQL
    local mysql_cmd="mysql"
    if [ -n "$mysql_pwd" ]; then
        mysql_cmd="mysql -u root -p'$mysql_pwd'"
    fi

    # Probar conexión MySQL
    if ! eval "$mysql_cmd -e 'SELECT 1'" > /dev/null 2>&1; then
        print_message "   ❌ No se pudo conectar a MySQL." "$RED"
        return 1
    fi

    # Verificar si la base de datos existe
    if eval "$mysql_cmd -e \"SHOW DATABASES LIKE '$db_name'\"" | grep -q "$db_name"; then
        print_message "   ¿Eliminar base de datos: $db_name? (s/n)" "$YELLOW"
        read -p "> " confirm_delete_db

        if [[ $confirm_delete_db == "s" || $confirm_delete_db == "S" ]]; then
            print_message "   Eliminando base de datos: $db_name" "$BLUE"
            eval "$mysql_cmd -e \"DROP DATABASE \\\`$db_name\\\`;\""
            print_message "   ✅ Base de datos eliminada" "$GREEN"
        else
            print_message "   Se omite la eliminación de la base de datos $db_name" "$YELLOW"
        fi
    else
        print_message "   Base de datos no encontrada: $db_name" "$YELLOW"
    fi

    # Verificar si el usuario existe
    if eval "$mysql_cmd -e \"SELECT User FROM mysql.user WHERE User='$db_user'\"" | grep -q "$db_user"; then
        print_message "   Eliminando usuario MySQL: $db_user" "$BLUE"
        eval "$mysql_cmd -e \"DROP USER IF EXISTS '$db_user'@'localhost';\""
        print_message "   ✅ Usuario eliminado" "$GREEN"
    else
        print_message "   Usuario MySQL no encontrado: $db_user" "$YELLOW"
    fi

    # Actualizar privilegios para aplicar cambios
    eval "$mysql_cmd -e \"FLUSH PRIVILEGES;\""
    print_message "✅ Limpieza de MySQL completada." "$GREEN"

    return 0
}