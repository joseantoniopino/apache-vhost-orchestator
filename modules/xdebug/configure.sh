#!/bin/bash

# Intelligent Xdebug configuration with state detection
# Follows the "detect current state and only make necessary changes" principle

configure_xdebug() {
    local PHP_VERSION=$1
    local REAL_USER=$2

    print_message "🐞 Configurando Xdebug..." "$BLUE"

    # 1. Detect if Xdebug is installed
    if ! php -m | grep -q "xdebug"; then
        print_message "   Xdebug no está instalado. Intentando instalarlo..." "$YELLOW"

        # Try to install Xdebug
        apt-get update -y > /dev/null
        apt-get install -y php$PHP_VERSION-xdebug > /dev/null 2>&1

        # Verify installation success
        if ! php -m | grep -q "xdebug"; then
            warning_message "No se pudo instalar Xdebug automáticamente. Puedes instalarlo manualmente con:"
            print_message "   sudo apt-get install php$PHP_VERSION-xdebug" "$BLUE"
            return 1
        else
            print_message "   ✅ Xdebug instalado correctamente." "$GREEN"
        fi
    else
        print_message "   ✅ Xdebug ya está instalado." "$GREEN"
    fi

    # 2. Find Xdebug configuration file
    local xdebug_ini_file="/etc/php/$PHP_VERSION/mods-available/xdebug.ini"

    if [ ! -f "$xdebug_ini_file" ]; then
        print_message "   Buscando archivo de configuración de Xdebug..." "$YELLOW"

        # Try to find the configuration file in other locations
        for dir in /etc/php/*; do
            if [ -d "$dir/mods-available" ] && [ -f "$dir/mods-available/xdebug.ini" ]; then
                xdebug_ini_file="$dir/mods-available/xdebug.ini"
                print_message "   ✅ Archivo de configuración encontrado en: $xdebug_ini_file" "$GREEN"
                break
            fi
        done

        if [ ! -f "$xdebug_ini_file" ]; then
            warning_message "No se pudo encontrar el archivo de configuración de Xdebug."
            return 1
        fi
    else
        print_message "   ✅ Archivo de configuración encontrado en: $xdebug_ini_file" "$GREEN"
    fi

    # 3. Analyze current Xdebug configuration
    print_message "   Analizando configuración actual de Xdebug..." "$BLUE"

    local needs_update=0
    local current_mode=$(grep -E "^xdebug.mode" "$xdebug_ini_file" | cut -d= -f2- | tr -d ' ')
    local current_start=$(grep -E "^xdebug.start_with_request" "$xdebug_ini_file" | cut -d= -f2- | tr -d ' ')
    local current_client_host=$(grep -E "^xdebug.client_host" "$xdebug_ini_file" | cut -d= -f2- | tr -d ' ')
    local current_client_port=$(grep -E "^xdebug.client_port" "$xdebug_ini_file" | cut -d= -f2- | tr -d ' ')
    local current_log=$(grep -E "^xdebug.log" "$xdebug_ini_file" | cut -d= -f2- | tr -d ' ')

    # Check if any setting needs updating
    if [ "$current_mode" != "debug" ]; then
        needs_update=1
        print_message "   - Modo de Xdebug necesita ser actualizado" "$YELLOW"
    fi

    if [ "$current_start" != "yes" ]; then
        needs_update=1
        print_message "   - Configuración de inicio automático necesita ser actualizada" "$YELLOW"
    fi

    if [ "$current_client_host" != "localhost" ]; then
        needs_update=1
        print_message "   - Host del cliente necesita ser actualizado" "$YELLOW"
    fi

    if [ "$current_client_port" != "9003" ]; then
        needs_update=1
        print_message "   - Puerto del cliente necesita ser actualizado" "$YELLOW"
    fi

    if [ "$current_log" != "/var/log/xdebug/xdebug.log" ]; then
        needs_update=1
        print_message "   - Ruta del log necesita ser actualizada" "$YELLOW"
    fi

    # 4. Create/verify log directory
    local xdebug_log_dir="/var/log/xdebug"
    if [ ! -d "$xdebug_log_dir" ]; then
        print_message "   Creando directorio para logs de Xdebug..." "$BLUE"
        mkdir -p "$xdebug_log_dir"
        chmod 777 "$xdebug_log_dir"
        chown "$REAL_USER":"$REAL_USER" "$xdebug_log_dir"
        print_message "   ✅ Directorio de logs creado: $xdebug_log_dir" "$GREEN"
    else
        # Check permissions on existing log directory
        if [ "$(stat -c '%a' "$xdebug_log_dir")" != "777" ]; then
            print_message "   Actualizando permisos del directorio de logs..." "$BLUE"
            chmod 777 "$xdebug_log_dir"
            chown "$REAL_USER":"$REAL_USER" "$xdebug_log_dir"
            print_message "   ✅ Permisos actualizados" "$GREEN"
        fi
    fi

    # 5. Update configuration if needed - preserving custom settings
    if [ "$needs_update" -eq 1 ]; then
        print_message "   Actualizando configuración de Xdebug..." "$BLUE"

        # Create backup of original configuration with timestamp
        cp "$xdebug_ini_file" "${xdebug_ini_file}.bak.$(date +%Y%m%d%H%M%S)"
        print_message "   ✅ Backup creado: ${xdebug_ini_file}.bak.$(date +%Y%m%d%H%M%S)" "$GREEN"

        # Update configuration while preserving custom settings
        if grep -q "zend_extension" "$xdebug_ini_file"; then
            # Update existing configuration by selectively replacing/adding lines
            sed -i '/xdebug.mode/d' "$xdebug_ini_file"
            sed -i '/xdebug.start_with_request/d' "$xdebug_ini_file"
            sed -i '/xdebug.client_host/d' "$xdebug_ini_file"
            sed -i '/xdebug.client_port/d' "$xdebug_ini_file"
            sed -i '/xdebug.log/d' "$xdebug_ini_file"

            # Add updated settings at the end of the file
            echo "xdebug.mode = debug" >> "$xdebug_ini_file"
            echo "xdebug.start_with_request = yes" >> "$xdebug_ini_file"
            echo "xdebug.client_host = localhost" >> "$xdebug_ini_file"
            echo "xdebug.client_port = 9003" >> "$xdebug_ini_file"
            echo "xdebug.log = /var/log/xdebug/xdebug.log" >> "$xdebug_ini_file"
        else
            # Create new configuration if basic structure is missing
            cat > "$xdebug_ini_file" << EOF
zend_extension=xdebug.so
xdebug.mode = debug
xdebug.start_with_request = yes
xdebug.client_host = localhost
xdebug.client_port = 9003
xdebug.log = /var/log/xdebug/xdebug.log
EOF
        fi

        print_message "   ✅ Configuración actualizada" "$GREEN"
    else
        print_message "   ✅ Configuración actual de Xdebug ya es correcta" "$GREEN"
    fi

    # 6. Restart services to apply changes
    if [ "$needs_update" -eq 1 ]; then
        print_message "   Reiniciando servicios para aplicar cambios..." "$BLUE"

        # Restart PHP-FPM if available
        if systemctl list-units --type=service | grep -q "php$PHP_VERSION-fpm"; then
            systemctl restart php$PHP_VERSION-fpm
            print_message "   ✅ PHP-FPM reiniciado" "$GREEN"
        elif systemctl list-units --type=service | grep -q "php-fpm"; then
            systemctl restart php-fpm
            print_message "   ✅ PHP-FPM reiniciado" "$GREEN"
        fi

        # Restart Apache
        systemctl restart apache2
        print_message "   ✅ Apache reiniciado" "$GREEN"
    fi

    # 7. Verify Xdebug is working
    print_message "   Verificando que Xdebug está funcionando correctamente..." "$BLUE"
    if php -m | grep -q "xdebug"; then
        print_message "✅ Xdebug está correctamente configurado y funcionando." "$GREEN"
        return 0
    else
        warning_message "Xdebug no está funcionando correctamente después de la configuración."
        warning_message "Revisa los logs de PHP para más información."
        return 1
    fi
}