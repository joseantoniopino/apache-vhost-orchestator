#!/bin/bash

# Laravel framework detector

# Detects if a project directory contains a Laravel project
detect_laravel() {
    local project_path=$1

    # Check for key Laravel files and directories
    if [ -f "$project_path/artisan" ] && \
       [ -d "$project_path/app" ] && \
       [ -d "$project_path/public" ] && \
       [ -f "$project_path/composer.json" ]; then

        # Additional check: verify composer.json contains laravel/framework
        if grep -q "laravel/framework" "$project_path/composer.json" 2>/dev/null; then
            return 0  # Return true (Laravel detected)
        fi
    fi

    return 1  # Return false (Not Laravel)
}

# Configure Laravel-specific settings
# This function sets up Laravel-specific configurations
configure_laravel() {
    local project_path=$1
    local domain=$2

    print_message "🚀 Configurando proyecto Laravel..." "$BLUE"

    # Configure permissions
    configure_laravel_permissions "$project_path"

    # Configure Vite for Laravel
    configure_laravel_vite "$project_path" "$domain"

    # Configure .env file
    configure_laravel_env "$project_path" "$domain"

    print_message "✅ Configuración de Laravel completada." "$GREEN"
}

# Configure Laravel permissions
configure_laravel_permissions() {
    local project_path=$1
    local www_user="www-data"  # Apache user on Ubuntu

    print_message "   Configurando permisos para Laravel..." "$BLUE"

    # Set permissions
    find "$project_path" -type f -exec chmod 644 {} \;
    find "$project_path" -type d -exec chmod 755 {} \;

    # Special permissions for storage and bootstrap/cache
    if [ -d "$project_path/storage" ]; then
        find "$project_path/storage" -type d -exec chmod 775 {} \;
        find "$project_path/storage" -type f -exec chmod 664 {} \;
    fi

    if [ -d "$project_path/bootstrap/cache" ]; then
        find "$project_path/bootstrap/cache" -type d -exec chmod 775 {} \;
        find "$project_path/bootstrap/cache" -type f -exec chmod 664 {} \;
    fi

    # Fix permissions for node_modules/.bin if exists
    if [ -d "$project_path/node_modules/.bin" ]; then
        find "$project_path/node_modules/.bin" -type f -exec chmod +x {} \;
    fi

    # Set ownership
    chown -R "$REAL_USER":"$REAL_USER" "$project_path"
    if [ -d "$project_path/storage" ]; then
        chgrp -R "$www_user" "$project_path/storage"
    fi
    if [ -d "$project_path/bootstrap/cache" ]; then
        chgrp -R "$www_user" "$project_path/bootstrap/cache"
    fi

    print_message "   ✅ Permisos configurados" "$GREEN"
}

# Configure Vite for Laravel
configure_laravel_vite() {
    local project_path=$1
    local domain=$2

    print_message "   Configurando Vite para Laravel..." "$BLUE"

    if [ ! -f "$project_path/vite.config.js" ]; then
        warning_message "No se encontró vite.config.js en el proyecto."
        return
    fi

    # Backup original file
    cp "$project_path/vite.config.js" "$project_path/vite.config.js.bak"

    # Check for existing server configuration
    if grep -q "server:" "$project_path/vite.config.js"; then
        # Update existing server configuration
        if grep -q "host:" "$project_path/vite.config.js" && grep -q "hmr:" "$project_path/vite.config.js"; then
            # Just update the domain
            sed -i "s/host: \"[^\"]*\"/host: \"$domain\"/g" "$project_path/vite.config.js"
        else
            # Replace server block with complete configuration
            TMP_FILE=$(mktemp)
            awk '
                BEGIN { skip = 0; level = 0; }
                /server:/ {
                    if (level == 0) {
                        skip = 1;
                        level = 1;
                        next;
                    }
                }
                skip && /{/ { level++; }
                skip && /},?/ {
                    level--;
                    if (level == 0) {
                        skip = 0;
                        print "    server: {";
                        print "        host: \"0.0.0.0\",";
                        print "        hmr: {";
                        print "            host: \"'"$domain"'\",";
                        print "        },";
                        if (match($0, /},$/)) print "    },";
                        else print "    }";
                        next;
                    }
                }
                !skip { print $0; }
            ' "$project_path/vite.config.js" > "$TMP_FILE"
            mv "$TMP_FILE" "$project_path/vite.config.js"
        fi
    else
        # Add new server configuration
        sed -i '/});/ i\    server: {\n        host: "0.0.0.0",\n        hmr: {\n            host: "'"$domain"'",\n        },\n    },' "$project_path/vite.config.js"
    fi

    # Ensure correct ownership
    chown "$REAL_USER":"$REAL_USER" "$project_path/vite.config.js"
    chown "$REAL_USER":"$REAL_USER" "$project_path/vite.config.js.bak"

    print_message "   ✅ Vite configurado para dominio: $domain" "$GREEN"
}

# Añadir dentro de configure_laravel() en laravel.sh, después de la línea que configura .env
# Configure .env file
configure_laravel_env() {
    local project_path=$1
    local domain=$2
    local db_engine=$3  # Opcional, para cuando se pasa explícitamente

    print_message "   Configurando archivo .env..." "$BLUE"

    local env_file="$project_path/.env"

    # Create .env from .env.example if needed
    if [ ! -f "$env_file" ] && [ -f "$project_path/.env.example" ]; then
        cp "$project_path/.env.example" "$env_file"
        chown "$REAL_USER":"$REAL_USER" "$env_file"
    elif [ ! -f "$env_file" ]; then
        warning_message "No se encontró archivo .env ni .env.example."
        return
    fi

    # Backup original file
    cp "$env_file" "${env_file}.bak"

    # Update APP_URL
    sed -i -E "s|^#?[[:space:]]*(APP_URL=).*|APP_URL=http://$domain|g" "$env_file"

    print_message "   ✅ Archivo .env configurado" "$GREEN"
}

# Función para configurar .env de Laravel según el motor de base de datos
configure_laravel_db_env() {
    local project_path=$1
    local db_engine=$2
    local db_name=$3
    local db_user=$4
    local db_pass=$5
    local db_host=$6
    local db_port=$7
    local db_file=$8  # Para SQLite

    local env_file="$project_path/.env"

    print_message "   Configurando parámetros de base de datos en .env..." "$BLUE"

    # Primero establecer el motor de base de datos
    case "$db_engine" in
        "mysql")
            sed -i -E 's/^#?[[:space:]]*(DB_CONNECTION=).*$/DB_CONNECTION=mysql/' "$env_file"
            ;;
        "postgresql")
            sed -i -E 's/^#?[[:space:]]*(DB_CONNECTION=).*$/DB_CONNECTION=pgsql/' "$env_file"
            ;;
        "sqlite")
            sed -i -E 's/^#?[[:space:]]*(DB_CONNECTION=).*$/DB_CONNECTION=sqlite/' "$env_file"
            ;;
        "sqlserver")
            sed -i -E 's/^#?[[:space:]]*(DB_CONNECTION=).*$/DB_CONNECTION=sqlsrv/' "$env_file"
            ;;
        "mongodb")
            sed -i -E 's/^#?[[:space:]]*(DB_CONNECTION=).*$/DB_CONNECTION=mongodb/' "$env_file"
            ;;
    esac

    # Configurar el resto de parámetros según el motor
    case "$db_engine" in
        "mysql"|"postgresql"|"sqlserver")
            # Descomentamos y configuramos host, puerto, nombre, usuario y contraseña
            sed -i -E 's/^#?[[:space:]]*(DB_HOST=).*$/DB_HOST='$db_host'/' "$env_file"
            sed -i -E 's/^#?[[:space:]]*(DB_PORT=).*$/DB_PORT='$db_port'/' "$env_file"
            sed -i -E 's/^#?[[:space:]]*(DB_DATABASE=).*$/DB_DATABASE='$db_name'/' "$env_file"
            sed -i -E 's/^#?[[:space:]]*(DB_USERNAME=).*$/DB_USERNAME='$db_user'/' "$env_file"
            sed -i -E 's/^#?[[:space:]]*(DB_PASSWORD=).*$/DB_PASSWORD='$db_pass'/' "$env_file"
            ;;

        "sqlite")
            # Para SQLite, comentamos los parámetros innecesarios
            sed -i -E '/^DB_HOST=/s/^/#/' "$env_file"
            sed -i -E '/^DB_PORT=/s/^/#/' "$env_file"
            sed -i -E '/^DB_USERNAME=/s/^/#/' "$env_file"
            sed -i -E '/^DB_PASSWORD=/s/^/#/' "$env_file"

            # Y establecemos la ruta del archivo de base de datos
            if grep -q "^#\?[[:space:]]*DB_DATABASE=" "$env_file"; then
                # Si existe, lo actualizamos
                sed -i -E 's|^#?[[:space:]]*(DB_DATABASE=).*$|DB_DATABASE='$db_file'|' "$env_file"
            else
                # Si no existe, lo añadimos
                echo "DB_DATABASE=$db_file" >> "$env_file"
            fi
            ;;

        "mongodb")
            # Para MongoDB, configuramos los parámetros específicos
            sed -i -E 's/^#?[[:space:]]*(DB_HOST=).*$/DB_HOST='$db_host'/' "$env_file"
            sed -i -E 's/^#?[[:space:]]*(DB_PORT=).*$/DB_PORT='$db_port'/' "$env_file"
            sed -i -E 's/^#?[[:space:]]*(DB_DATABASE=).*$/DB_DATABASE='$db_name'/' "$env_file"

            # Verificamos si necesitamos autenticación
            if [ -n "$db_user" ] && [ -n "$db_pass" ]; then
                sed -i -E 's/^#?[[:space:]]*(DB_USERNAME=).*$/DB_USERNAME='$db_user'/' "$env_file"
                sed -i -E 's/^#?[[:space:]]*(DB_PASSWORD=).*$/DB_PASSWORD='$db_pass'/' "$env_file"
            else
                # Si no hay autenticación, comentamos estos campos
                sed -i -E '/^DB_USERNAME=/s/^/#/' "$env_file"
                sed -i -E '/^DB_PASSWORD=/s/^/#/' "$env_file"
            fi

            # Agregar parámetros específicos de MongoDB si no existen
            if ! grep -q "MONGODB_AUTHENTICATION_DATABASE" "$env_file"; then
                echo "MONGODB_AUTHENTICATION_DATABASE=admin" >> "$env_file"
            fi
            ;;
    esac

    print_message "   ✅ Parámetros de base de datos configurados correctamente para $db_engine" "$GREEN"
}