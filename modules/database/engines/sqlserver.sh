#!/bin/bash

# Función específica para crear base de datos SQL Server
create_sqlserver_db() {
    local project_name=$1

    # Normalizar nombre del proyecto para SQL Server
    local db_name="${project_name}"
    local db_user="${project_name}_user"
    local db_pass="P@ssw0rd123"  # SQL Server requiere contraseñas complejas

    print_message "🗄️ Creando base de datos SQL Server: $db_name" "$BLUE"

    # Solicitar credenciales de administrador
    read -p "Introduce el servidor SQL Server (localhost,1433 por defecto): " sqlserver_host
    sqlserver_host=${sqlserver_host:-"localhost,1433"}

    read -p "Introduce el usuario administrador de SQL Server (sa por defecto): " sqlserver_admin
    sqlserver_admin=${sqlserver_admin:-"sa"}

    read -sp "Introduce la contraseña del administrador: " sqlserver_admin_pass
    echo ""

    # Verificar conexión
    if ! sqlcmd -S "$sqlserver_host" -U "$sqlserver_admin" -P "$sqlserver_admin_pass" -Q "SELECT 1" &>/dev/null; then
        print_message "   ❌ No se puede conectar a SQL Server. Verifica credenciales y que el servidor esté corriendo." "$RED"
        return 1
    fi

    # Crear la base de datos
    print_message "   Creando base de datos $db_name..." "$BLUE"
    if sqlcmd -S "$sqlserver_host" -U "$sqlserver_admin" -P "$sqlserver_admin_pass" -Q "IF DB_ID('$db_name') IS NOT NULL DROP DATABASE [$db_name]; CREATE DATABASE [$db_name];" &>/dev/null; then
        print_message "   ✅ Base de datos creada correctamente" "$GREEN"
    else
        print_message "   ❌ Error al crear la base de datos" "$RED"
        return 1
    fi

    # Crear login y usuario
    print_message "   Creando usuario $db_user..." "$BLUE"
    if sqlcmd -S "$sqlserver_host" -U "$sqlserver_admin" -P "$sqlserver_admin_pass" -Q "
        IF EXISTS (SELECT * FROM sys.server_principals WHERE name = '$db_user')
            DROP LOGIN [$db_user];
        CREATE LOGIN [$db_user] WITH PASSWORD = '$db_pass', DEFAULT_DATABASE = [$db_name];
        USE [$db_name];
        CREATE USER [$db_user] FOR LOGIN [$db_user];
        ALTER ROLE db_owner ADD MEMBER [$db_user];
    " &>/dev/null; then
        print_message "   ✅ Usuario creado y permisos asignados correctamente" "$GREEN"
    else
        print_message "   ❌ Error al crear el usuario" "$RED"
        return 1
    fi

    print_message "✅ Base de datos SQL Server configurada correctamente." "$GREEN"

    # Devolver la configuración
    echo "DB_CONNECTION=sqlsrv"
    echo "DB_HOST=$sqlserver_host"
    echo "DB_PORT=1433"
    echo "DB_DATABASE=$db_name"
    echo "DB_USERNAME=$db_user"
    echo "DB_PASSWORD=$db_pass"

    return 0
}

# Función para limpiar bases de datos SQL Server
clean_sqlserver_db() {
    local project_name=$1

    # Normalizar nombre del proyecto
    local db_name="${project_name}"
    local db_user="${project_name}_user"

    print_message "🔄 Limpiando base de datos SQL Server para $project_name..." "$BLUE"

    # Solicitar credenciales de administrador
    read -p "Introduce el servidor SQL Server (localhost,1433 por defecto): " sqlserver_host
    sqlserver_host=${sqlserver_host:-"localhost,1433"}

    read -p "Introduce el usuario administrador de SQL Server (sa por defecto): " sqlserver_admin
    sqlserver_admin=${sqlserver_admin:-"sa"}

    read -sp "Introduce la contraseña del administrador: " sqlserver_admin_pass
    echo ""

    # Verificar conexión
    if ! sqlcmd -S "$sqlserver_host" -U "$sqlserver_admin" -P "$sqlserver_admin_pass" -Q "SELECT 1" &>/dev/null; then
        print_message "   ❌ No se puede conectar a SQL Server. Verifica credenciales y que el servidor esté corriendo." "$RED"
        return 1
    fi

    # Verificar si la base de datos existe
    if sqlcmd -S "$sqlserver_host" -U "$sqlserver_admin" -P "$sqlserver_admin_pass" -Q "SELECT 1 FROM sys.databases WHERE name = '$db_name'" | grep -q "1"; then
        print_message "   ¿Eliminar base de datos: $db_name? (s/n)" "$YELLOW"
        read -p "> " confirm_delete_db

        if [[ $confirm_delete_db == "s" || $confirm_delete_db == "S" ]]; then
            print_message "   Eliminando base de datos: $db_name" "$BLUE"
            if sqlcmd -S "$sqlserver_host" -U "$sqlserver_admin" -P "$sqlserver_admin_pass" -Q "
                USE [master];
                ALTER DATABASE [$db_name] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
                DROP DATABASE [$db_name];
            " &>/dev/null; then
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

    # Verificar si el login existe
    if sqlcmd -S "$sqlserver_host" -U "$sqlserver_admin" -P "$sqlserver_admin_pass" -Q "SELECT 1 FROM sys.server_principals WHERE name = '$db_user'" | grep -q "1"; then
        print_message "   Eliminando login de SQL Server: $db_user" "$BLUE"
        if sqlcmd -S "$sqlserver_host" -U "$sqlserver_admin" -P "$sqlserver_admin_pass" -Q "DROP LOGIN [$db_user];" &>/dev/null; then
            print_message "   ✅ Login eliminado" "$GREEN"
        else
            print_message "   ❌ No se pudo eliminar el login" "$RED"
        fi
    else
        print_message "   Login de SQL Server no encontrado: $db_user" "$YELLOW"
    fi

    print_message "✅ Limpieza de SQL Server completada." "$GREEN"

    return 0
}