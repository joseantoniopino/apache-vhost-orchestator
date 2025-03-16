#!/bin/bash

# Función específica para crear base de datos MongoDB
create_mongodb_db() {
    local project_name=$1

    # Normalizar nombre del proyecto para MongoDB
    local db_name="${project_name}"
    local db_user="${project_name}_user"
    local db_pass="password123"  # Contraseña simple para desarrollo

    print_message "🗄️ Creando base de datos MongoDB: $db_name" "$BLUE"

    # Determinar el comando MongoDB a usar (mongo o mongosh)
    local mongo_cmd=""
    if command -v mongosh &> /dev/null; then
        mongo_cmd="mongosh"
    elif command -v mongo &> /dev/null; then
        mongo_cmd="mongo"
    else
        print_message "   ❌ No se encontró el cliente de MongoDB (mongo o mongosh)" "$RED"
        return 1
    fi

    # Preguntar por la configuración de MongoDB
    read -p "¿Usar autenticación para MongoDB? (s/n): " use_auth
    local auth_params=""
    local mongo_host="localhost"
    local mongo_port="27017"

    if [[ $use_auth == "s" || $use_auth == "S" ]]; then
        read -p "Introduce el usuario administrador de MongoDB: " mongo_admin
        read -sp "Introduce la contraseña del administrador: " mongo_admin_pass
        echo ""
        read -p "Introduce el host de MongoDB (default: localhost): " input_host
        mongo_host=${input_host:-"localhost"}
        read -p "Introduce el puerto de MongoDB (default: 27017): " input_port
        mongo_port=${input_port:-"27017"}

        auth_params="--host $mongo_host:$mongo_port -u $mongo_admin -p $mongo_admin_pass --authenticationDatabase admin"
    fi

    # Crear la base de datos y el usuario
    print_message "   Creando base de datos y usuario..." "$BLUE"

    # En MongoDB, las bases de datos se crean al insertarse el primer documento
    # y los usuarios se crean con comandos específicos
    local create_script=$(cat <<EOF
use $db_name;
db.createCollection("init");
if (db.getUser("$db_user")) { db.dropUser("$db_user"); }
db.createUser({
  user: "$db_user",
  pwd: "$db_pass",
  roles: [{ role: "readWrite", db: "$db_name" }]
});
EOF
)

    if [ "$mongo_cmd" = "mongo" ]; then
        # Para el cliente mongo legacy
        if [ -n "$auth_params" ]; then
            echo "$create_script" | eval "$mongo_cmd $auth_params" &>/dev/null
        else
            echo "$create_script" | mongo &>/dev/null
        fi
    else
        # Para mongosh
        if [ -n "$auth_params" ]; then
            echo "$create_script" | eval "$mongo_cmd $auth_params" &>/dev/null
        else
            echo "$create_script" | mongosh &>/dev/null
        fi
    fi

    if [ $? -eq 0 ]; then
        print_message "   ✅ Base de datos y usuario creados correctamente" "$GREEN"

        # Devolver configuración
        echo "DB_CONNECTION=mongodb"
        echo "DB_HOST=$mongo_host"
        echo "DB_PORT=$mongo_port"
        echo "DB_DATABASE=$db_name"
        echo "DB_USERNAME=$db_user"
        echo "DB_PASSWORD=$db_pass"

        return 0
    else
        print_message "   ❌ Error al crear la base de datos o el usuario" "$RED"
        return 1
    fi
}

# Función para limpiar bases de datos MongoDB
clean_mongodb_db() {
    local project_name=$1

    # Normalizar nombre del proyecto
    local db_name="${project_name}"
    local db_user="${project_name}_user"

    print_message "🔄 Limpiando base de datos MongoDB para $project_name..." "$BLUE"

    # Determinar el comando MongoDB a usar
    local mongo_cmd=""
    if command -v mongosh &> /dev/null; then
        mongo_cmd="mongosh"
    elif command -v mongo &> /dev/null; then
        mongo_cmd="mongo"
    else
        print_message "   ❌ No se encontró el cliente de MongoDB (mongo o mongosh)" "$RED"
        return 1
    fi

    # Preguntar por la configuración de MongoDB
    read -p "¿Usar autenticación para MongoDB? (s/n): " use_auth
    local auth_params=""
    local mongo_host="localhost"
    local mongo_port="27017"

    if [[ $use_auth == "s" || $use_auth == "S" ]]; then
        read -p "Introduce el usuario administrador de MongoDB: " mongo_admin
        read -sp "Introduce la contraseña del administrador: " mongo_admin_pass
        echo ""
        read -p "Introduce el host de MongoDB (default: localhost): " input_host
        mongo_host=${input_host:-"localhost"}
        read -p "Introduce el puerto de MongoDB (default: 27017): " input_port
        mongo_port=${input_port:-"27017"}

        auth_params="--host $mongo_host:$mongo_port -u $mongo_admin -p $mongo_admin_pass --authenticationDatabase admin"
    fi

    # Verificar si la base de datos existe
    local check_script="db.adminCommand('listDatabases').databases.forEach(function(d) { if(d.name === '$db_name') { print('found'); } });"

    local db_exists=""
    if [ "$mongo_cmd" = "mongo" ]; then
        if [ -n "$auth_params" ]; then
            db_exists=$(echo "$check_script" | eval "$mongo_cmd $auth_params" | grep "found")
        else
            db_exists=$(echo "$check_script" | mongo | grep "found")
        fi
    else
        if [ -n "$auth_params" ]; then
            db_exists=$(echo "$check_script" | eval "$mongo_cmd $auth_params" | grep "found")
        else
            db_exists=$(echo "$check_script" | mongosh | grep "found")
        fi
    fi

    if [ -n "$db_exists" ]; then
        print_message "   ¿Eliminar base de datos: $db_name? (s/n)" "$YELLOW"
        read -p "> " confirm_delete_db

        if [[ $confirm_delete_db == "s" || $confirm_delete_db == "S" ]]; then
            print_message "   Eliminando base de datos y usuario: $db_name" "$BLUE"

            local drop_script=$(cat <<EOF
use $db_name;
if (db.getUser("$db_user")) { db.dropUser("$db_user"); }
db.dropDatabase();
EOF
)

            if [ "$mongo_cmd" = "mongo" ]; then
                if [ -n "$auth_params" ]; then
                    echo "$drop_script" | eval "$mongo_cmd $auth_params" &>/dev/null
                else
                    echo "$drop_script" | mongo &>/dev/null
                fi
            else
                if [ -n "$auth_params" ]; then
                    echo "$drop_script" | eval "$mongo_cmd $auth_params" &>/dev/null
                else
                    echo "$drop_script" | mongosh &>/dev/null
                fi
            fi

            if [ $? -eq 0 ]; then
                print_message "   ✅ Base de datos y usuario eliminados" "$GREEN"
            else
                print_message "   ❌ Error al eliminar la base de datos o el usuario" "$RED"
            fi
        else
            print_message "   Se omite la eliminación de la base de datos $db_name" "$YELLOW"
        fi
    else
        print_message "   Base de datos no encontrada: $db_name" "$YELLOW"
    fi

    print_message "✅ Limpieza de MongoDB completada." "$GREEN"

    return 0
}