#!/bin/bash

# Script para configurar el entorno de desarrollo para proyectos Laravel
# Autor: Tu nombre
# Fecha: $(date +%Y-%m-%d)

# Variables de entorno
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)
ACTIONS_FILE="/tmp/laravel_setup_actions"

# Detectar PHP disponible
PHP_VERSION=""
for version in "8.4" "8.3" "8.2" "8.1" "8.0" "7.4"; do
    if command -v php$version &> /dev/null; then
        PHP_VERSION="$version"
        break
    fi
done

if [ -z "$PHP_VERSION" ]; then
    # Si no se encontró una versión específica, intentar con php genérico
    if command -v php &> /dev/null; then
        PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    else
        PHP_VERSION="8.2" # Versión predeterminada si no se puede detectar
    fi
fi

# Detectar el shell del usuario
USER_SHELL=$(getent passwd $REAL_USER | cut -d: -f7)
if [[ "$USER_SHELL" == *"zsh"* ]]; then
    RC_FILE="$REAL_HOME/.zshrc"
    SHELL_TYPE="zsh"
    print_shell_message="zsh detectado - usando $RC_FILE"
else
    RC_FILE="$REAL_HOME/.bashrc"
    SHELL_TYPE="bash"
    print_shell_message="bash detectado - usando $RC_FILE"
fi

# Colores para mensajes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Array para registrar acciones realizadas (para rollback)
ACTIONS_DONE=()

# Función para mostrar mensajes
print_message() {
    echo -e "${2}${1}${NC}"
}

# Función para mostrar mensajes de error y ejecutar rollback
error_exit() {
    print_message "ERROR: $1" "$RED"
    perform_rollback
    exit 1
}

# Función para mostrar mensajes de advertencia
warning_message() {
    print_message "ADVERTENCIA: $1" "$YELLOW"
}

# Función para registrar acciones (para rollback)
register_action() {
    ACTIONS_DONE+=("$1")
    echo "$1" >> "$ACTIONS_FILE"
}

# Función para capturar señales (Ctrl+C, etc.)
trap_handler() {
    print_message "\n⚠️ Operación interrumpida por el usuario." "$YELLOW"
    perform_rollback
    exit 1
}

# Configurar captura de señales
trap trap_handler SIGINT SIGTERM

# Función para realizar rollback de las acciones completadas
perform_rollback() {
    # Leer las acciones desde el archivo (si existe)
    if [ -f "$ACTIONS_FILE" ]; then
        while IFS= read -r line; do
            ACTIONS_DONE+=("$line")
        done < "$ACTIONS_FILE"
    fi
    
    if [ ${#ACTIONS_DONE[@]} -eq 0 ]; then
        print_message "No hay acciones que deshacer." "$YELLOW"
        return
    fi
    
    print_message "\n🔄 Realizando rollback de las acciones completadas..." "$YELLOW"
    
    # Recorrer el array de acciones en orden inverso
    for ((i=${#ACTIONS_DONE[@]}-1; i>=0; i--)); do
        action="${ACTIONS_DONE[$i]}"
        print_message "➡️ Deshaciendo: $action" "$YELLOW"
        
        case "$action" in
            "hosts_modified:"*)
                domain="${action#hosts_modified:}"
                print_message "   Eliminando entrada en /etc/hosts para: $domain" "$YELLOW"
                sed -i "/127.0.0.1\s*$domain/d" /etc/hosts
                ;;
            "vhost_created:"*)
                domain="${action#vhost_created:}"
                print_message "   Eliminando virtual host: $domain" "$YELLOW"
                a2dissite "${domain}.conf" > /dev/null 2>&1
                rm -f "/etc/apache2/sites-available/${domain}.conf"
                systemctl restart apache2 > /dev/null 2>&1
                ;;
            "database_created:"*)
                db_name="${action#database_created:}"
                print_message "   Eliminando base de datos: $db_name" "$YELLOW"
                mysql -u root -e "DROP DATABASE IF EXISTS \`$db_name\`;" 2>/dev/null
                ;;
            "vite_configured:"*)
                config_file="${action#vite_configured:}"
                backup_file="${config_file}.bak"
                if [ -f "$backup_file" ]; then
                    print_message "   Restaurando configuración original de Vite" "$YELLOW"
                    mv "$backup_file" "$config_file"
                fi
                ;;
            "env_modified:"*)
                env_file="${action#env_modified:}"
                backup_file="${env_file}.bak"
                if [ -f "$backup_file" ]; then
                    print_message "   Restaurando archivo .env original" "$YELLOW"
                    mv "$backup_file" "$env_file"
                fi
                ;;
        esac
    done
    
    # Limpiar el archivo de acciones
    rm -f "$ACTIONS_FILE"
    
    print_message "✅ Rollback completado." "$YELLOW"
    
    # Al final de un rollback exitoso, salir limpiamente
    trap - EXIT
    exit 0
}

# Verificar si se están ejecutando como root (necesario para modificar /etc/hosts)
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "Este script debe ejecutarse con privilegios de superusuario (root) para modificar /etc/hosts y configurar Apache."
    fi
}

# Verificar dependencias necesarias
check_dependencies() {
    print_message "⚙️ Verificando dependencias necesarias..." "$BLUE"
    print_message "🔍 $print_shell_message" "$BLUE"
    
    # Verificar PHP
    if ! command -v php$PHP_VERSION &> /dev/null && ! command -v php &> /dev/null; then
        error_exit "PHP $PHP_VERSION no está instalado. Por favor, instálalo usando:\n sudo add-apt-repository ppa:ondrej/php -y && sudo apt update && sudo apt install php$PHP_VERSION php$PHP_VERSION-cli php$PHP_VERSION-common php$PHP_VERSION-curl php$PHP_VERSION-mbstring php$PHP_VERSION-xml php$PHP_VERSION-zip php$PHP_VERSION-mysql php$PHP_VERSION-bcmath php$PHP_VERSION-gd php$PHP_VERSION-opcache php$PHP_VERSION-xdebug -y"
    fi
    
    # Verificar Apache
    if ! command -v apache2ctl &> /dev/null; then
        error_exit "Apache2 no está instalado. Por favor, instálalo usando:\n sudo add-apt-repository ppa:ondrej/apache2 -y && sudo apt update && sudo apt install apache2 libapache2-mod-php$PHP_VERSION -y"
    fi
    
    print_message "✅ Verificación de dependencias completa." "$GREEN"
}

# Función para verificar si un proyecto Laravel existe y es válido
verify_laravel_project() {
    local project_path=$1
    
    if [ ! -d "$project_path" ]; then
        return 1
    fi
    
    # Verificar archivos y directorios clave de Laravel
    if [ ! -d "$project_path/app" ] || [ ! -d "$project_path/public" ] || [ ! -f "$project_path/artisan" ]; then
        return 1
    fi
    
    return 0
}

# Función para obtener información del proyecto
get_project_info() {
    local default_base_path="$REAL_HOME/www/laravel"
    
    # Solicitar nombre del proyecto
    while true; do
        read -p "Ingresa el nombre del proyecto Laravel: " project_name
        
        if [ -z "$project_name" ]; then
            warning_message "El nombre del proyecto no puede estar vacío."
        elif [[ ! "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            warning_message "El nombre del proyecto solo puede contener letras, números, guiones y guiones bajos."
        else
            break
        fi
    done
    
    # Construir la ruta predeterminada
    local default_project_path="$default_base_path/$project_name"
    
    # Solicitar la ruta del proyecto
    while true; do
        read -p "Ingresa la ruta completa del proyecto Laravel [$default_project_path]: " input_project_path
        project_path=${input_project_path:-$default_project_path}
        
        # Verificar si el proyecto existe y es válido
        if verify_laravel_project "$project_path"; then
            print_message "✅ Proyecto Laravel encontrado en: $project_path" "$GREEN"
            break
        else
            warning_message "No se encontró un proyecto Laravel válido en: $project_path"
            read -p "¿Quieres intentar con otra ruta? (s/n): " try_again
            if [[ $try_again != "s" && $try_again != "S" ]]; then
                error_exit "No se encontró un proyecto Laravel válido. Asegúrate de crear el proyecto primero."
            fi
        fi
    done
    
    # Extraer el nombre del directorio como nombre del proyecto si es diferente
    local dir_name=$(basename "$project_path")
    if [ "$project_name" != "$dir_name" ]; then
        warning_message "El nombre del proyecto ($project_name) es diferente al nombre del directorio ($dir_name)."
        read -p "¿Quieres usar '$dir_name' como nombre del proyecto? (s/n): " use_dirname
        if [[ $use_dirname == "s" || $use_dirname == "S" ]]; then
            project_name="$dir_name"
        fi
    fi
    
    # Solicitar dominio local
    local default_domain="${project_name}.test"
    read -p "Ingresa el dominio local para el proyecto [$default_domain]: " input_domain
    domain=${input_domain:-$default_domain}
    
    # Validar el formato del dominio
    if [[ ! "$domain" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        warning_message "El dominio contiene caracteres no válidos. Se usará el dominio predeterminado: $default_domain"
        domain="$default_domain"
    fi
    
    # Mostrar resumen de la información
    print_message "\n==== INFORMACIÓN DEL PROYECTO ====" "$GREEN"
    print_message "Nombre del proyecto: $project_name" "$BLUE"
    print_message "Ruta del proyecto: $project_path" "$BLUE"
    print_message "Dominio local: $domain" "$BLUE"
    
    read -p "¿Es correcta esta información? (s/n): " confirm
    if [[ $confirm != "s" && $confirm != "S" ]]; then
        error_exit "Operación cancelada por el usuario."
    fi
}

# Configurar permisos para el proyecto Laravel
configure_permissions() {
    local project_path=$1
    local www_user="www-data"  # Usuario de Apache en Ubuntu
    
    print_message "🔒 Configurando permisos para el proyecto..." "$BLUE"
    
    # Comprobar que el directorio del proyecto existe
    if [ ! -d "$project_path" ]; then
        error_exit "No se puede configurar permisos: el directorio del proyecto no existe."
    fi
    
    # Cambiar al directorio del proyecto
    cd "$project_path" || error_exit "No se pudo acceder al directorio del proyecto"
    
    # Configurar permisos
    find . -type f -exec chmod 644 {} \;
    find . -type d -exec chmod 755 {} \;
    
    # Configurar permisos especiales para storage y bootstrap/cache
    find storage bootstrap/cache -type d -exec chmod 775 {} \;
    find storage bootstrap/cache -type f -exec chmod 664 {} \;
    
    # Si existe el directorio node_modules, establecer permisos correctos
    if [ -d "$project_path/node_modules" ]; then
        print_message "   Corrigiendo permisos para node_modules/.bin..." "$BLUE"
        if [ -d "$project_path/node_modules/.bin" ]; then
            find "$project_path/node_modules/.bin" -type f -exec chmod +x {} \;
        fi
        chown -R "$REAL_USER":"$REAL_USER" "$project_path/node_modules"
    fi
    
    # Asignar propiedad
    chown -R "$REAL_USER":"$REAL_USER" .
    chgrp -R "$www_user" storage bootstrap/cache
    
    print_message "✅ Permisos configurados correctamente." "$GREEN"
}

# Configurar el archivo hosts
configure_hosts() {
    local domain=$1
    
    print_message "🌐 Configurando archivo hosts para dominio: $domain" "$BLUE"
    
    # Verificar si el dominio ya existe en /etc/hosts
    if grep -q "$domain" /etc/hosts; then
        warning_message "El dominio ya existe en /etc/hosts."
    else
        # Añadir dominio al archivo hosts
        echo "127.0.0.1   $domain" >> /etc/hosts
        
        # Registrar la acción para rollback
        register_action "hosts_modified:$domain"
        
        print_message "✅ Dominio añadido a /etc/hosts." "$GREEN"
    fi
}

# Configurar el virtual host de Apache
configure_vhost() {
    local project_path=$1
    local domain=$2
    
    print_message "🖥️ Configurando virtual host para: $domain" "$BLUE"
    
    # Crear archivo de configuración del virtual host
    local vhost_file="/etc/apache2/sites-available/${domain}.conf"
    
    # Detectar si php-fpm está instalado y usar la versión correcta
    local fpm_config=""
    if [ -S "/var/run/php/php${PHP_VERSION}-fpm.sock" ]; then
        fpm_config="<FilesMatch \\.php\$>
        SetHandler \"proxy:unix:/var/run/php/php${PHP_VERSION}-fpm.sock|fcgi://localhost\"
    </FilesMatch>"
    fi
    
    cat > "$vhost_file" << EOF
<VirtualHost *:80>
    ServerName ${domain}
    DocumentRoot ${project_path}/public

    <Directory ${project_path}/public>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${domain}-error.log
    CustomLog \${APACHE_LOG_DIR}/${domain}-access.log combined

    $fpm_config
</VirtualHost>
EOF
    
    # Habilitar el sitio
    a2ensite "${domain}.conf" > /dev/null 2>&1
    
    # Habilitar módulos necesarios
    a2enmod rewrite > /dev/null 2>&1
    
    # Habilitar proxy_fcgi solo si está disponible y php-fpm está instalado
    if [ -n "$fpm_config" ] && apache2ctl -M 2>/dev/null | grep -q "proxy_fcgi_module"; then
        a2enmod proxy_fcgi > /dev/null 2>&1
    fi
    
    # Reiniciar Apache
    systemctl restart apache2
    
    # Registrar la acción para rollback
    register_action "vhost_created:$domain"
    
    print_message "✅ Virtual host configurado correctamente." "$GREEN"
}

# Configurar Xdebug
configure_xdebug() {
    print_message "🐞 Configurando Xdebug..." "$BLUE"
    
    # Verificar si Xdebug está instalado
    if ! php -m | grep -q "xdebug"; then
        warning_message "Xdebug no está instalado. Intentando instalarlo..."
        
        # Intentar instalar Xdebug
        apt-get update -y > /dev/null
        apt-get install -y php$PHP_VERSION-xdebug > /dev/null 2>&1
        
        # Verificar si la instalación fue exitosa
        if ! php -m | grep -q "xdebug"; then
            warning_message "No se pudo instalar Xdebug automáticamente. Puedes instalarlo manualmente con:"
            print_message "sudo apt-get install php$PHP_VERSION-xdebug" "$BLUE"
            return
        fi
    fi
    
    # Verificar si xdebug ya está configurado
    xdebug_ini_file="/etc/php/$PHP_VERSION/mods-available/xdebug.ini"
    
    if [ ! -f "$xdebug_ini_file" ]; then
        warning_message "No se encontró el archivo de configuración de Xdebug en $xdebug_ini_file"
        
        # Intentar encontrar el archivo en otra ubicación
        for dir in /etc/php/*; do
            if [ -d "$dir/mods-available" ] && [ -f "$dir/mods-available/xdebug.ini" ]; then
                xdebug_ini_file="$dir/mods-available/xdebug.ini"
                break
            fi
        done
        
        if [ ! -f "$xdebug_ini_file" ]; then
            warning_message "No se pudo encontrar el archivo de configuración de Xdebug. Saltando configuración."
            return
        fi
    fi
    
    # Crear directorio de logs para Xdebug si no existe y establecer permisos
    local xdebug_log_dir="/var/log/xdebug"
    if [ ! -d "$xdebug_log_dir" ]; then
        mkdir -p "$xdebug_log_dir"
    fi
    
    # Establecer permisos para que el usuario normal pueda escribir
    chmod 777 "$xdebug_log_dir"
    chown "$REAL_USER":"$REAL_USER" "$xdebug_log_dir"
    
    # Hacer backup del archivo de configuración original
    cp "$xdebug_ini_file" "${xdebug_ini_file}.bak"
    
    # Configurar Xdebug con una ruta de log accesible para usuarios normales
    cat > "$xdebug_ini_file" << EOF
zend_extension=xdebug.so
xdebug.mode = debug
xdebug.start_with_request = yes
xdebug.client_host = localhost
xdebug.client_port = 9003
xdebug.log = /var/log/xdebug/xdebug.log
EOF
    
    # Reiniciar PHP-FPM si está disponible
    if systemctl list-units --type=service | grep -q "php$PHP_VERSION-fpm"; then
        systemctl restart php$PHP_VERSION-fpm
    elif systemctl list-units --type=service | grep -q "php-fpm"; then
        systemctl restart php-fpm
    fi
    
    # Reiniciar Apache
    systemctl restart apache2
    
    print_message "✅ Xdebug configurado correctamente." "$GREEN"
}

# Configurar Vite correctamente
configure_vite() {
    local project_path=$1
    local domain=$2
    
    print_message "📦 Configurando Vite..." "$BLUE"
    
    if [ ! -f "$project_path/vite.config.js" ]; then
        warning_message "No se encontró el archivo vite.config.js en $project_path."
        return
    fi
    
    # Hacer backup del archivo original
    cp "$project_path/vite.config.js" "$project_path/vite.config.js.bak"
    
    # Verificar si ya existe una configuración de servidor
    if grep -q "server:" "$project_path/vite.config.js"; then
        print_message "   Configuración de servidor existente detectada. Actualizando..." "$BLUE"
        
        # Verificar si ya tiene una configuración de host y hmr
        if grep -q "host:" "$project_path/vite.config.js" && grep -q "hmr:" "$project_path/vite.config.js"; then
            print_message "   La configuración de host y HMR ya existe. Actualizando para el dominio: $domain" "$BLUE"
            # Solo actualizar el dominio en la configuración hmr existente
            sed -i "s/host: \"[^\"]*\"/host: \"$domain\"/g" "$project_path/vite.config.js"
        else
            # Reemplazar la configuración server existente con una completa
            # Primero eliminamos el bloque server existente
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
        print_message "   Añadiendo nueva configuración de servidor..." "$BLUE"
        
        # Añadir la configuración del servidor justo antes del cierre del objeto principal
        sed -i '/});/ i\    server: {\n        host: "0.0.0.0",\n        hmr: {\n            host: "'"$domain"'",\n        },\n    },' "$project_path/vite.config.js"
    fi
    
    # Asegurarse de que el archivo pertenece al usuario correcto
    chown "$REAL_USER":"$REAL_USER" "$project_path/vite.config.js"
    chown "$REAL_USER":"$REAL_USER" "$project_path/vite.config.js.bak"
    
    # Registrar la acción para rollback
    register_action "vite_configured:$project_path/vite.config.js"
    
    print_message "✅ Vite configurado correctamente para el dominio $domain." "$GREEN"
}

# Configurar archivo .env
configure_env() {
    local project_path=$1
    local project_name=$2
    local domain=$3
    
    print_message "📝 Configurando archivo .env..." "$BLUE"
    
    local env_file="$project_path/.env"
    
    if [ ! -f "$env_file" ]; then
        warning_message "No se encontró el archivo .env en $project_path."
        warning_message "Si el archivo .env.example existe, se creará una copia."
        
        if [ -f "$project_path/.env.example" ]; then
            cp "$project_path/.env.example" "$env_file"
            chown "$REAL_USER":"$REAL_USER" "$env_file"
        else
            warning_message "No se encontró el archivo .env.example. Saltando configuración de .env."
            return
        fi
    fi
    
    # Hacer backup del archivo original
    cp "$env_file" "${env_file}.bak"
    
    # Registrar la acción para rollback
    register_action "env_modified:$env_file"
    
    # Asegurarnos de usar MySQL en lugar de SQLite
    sed -i -E 's/^#?[[:space:]]*(DB_CONNECTION=).*$/DB_CONNECTION=mysql/' "$env_file"
    
    # Actualizar URL de la aplicación
    sed -i -E "s|^#?[[:space:]]*(APP_URL=).*|APP_URL=http://$domain|g" "$env_file"
    
    print_message "✅ Archivo .env configurado correctamente." "$GREEN"
}

# Crear la base de datos para el proyecto
create_database() {
    local project_name=$1
    local project_path=$2
    local domain=$3
    
    # Preguntar si quiere crear la base de datos
    read -p "¿Quieres crear una base de datos para este proyecto? (s/n): " create_db
    if [[ $create_db != "s" && $create_db != "S" ]]; then
        return
    fi
    
    # Usar el nombre del proyecto como nombre de la base de datos
    local db_name="${project_name}"
    local db_user="${project_name}_user"
    local db_pass="password123"  # Contraseña simple para desarrollo local
    
    print_message "🗄️ Creando base de datos: $db_name" "$BLUE"
    
    # Verificar si MySQL está instalado
    if ! command -v mysql &> /dev/null; then
        warning_message "MySQL no está instalado. Saltando creación de base de datos."
        return
    fi
    
    # Preguntar por credenciales de MySQL si es necesario
    local mysql_root_pass=""
    local mysql_cmd="mysql"
    
    # Intentar primero sin contraseña
    if ! mysql -u root -e "SELECT 1" &>/dev/null; then
        print_message "Se requiere contraseña para el usuario root de MySQL." "$YELLOW"
        read -sp "Introduce la contraseña de root para MySQL: " mysql_root_pass
        echo ""
        
        # Probar si la contraseña funciona
        if ! mysql -u root -p"$mysql_root_pass" -e "SELECT 1" &>/dev/null; then
            warning_message "Contraseña incorrecta. No se puede acceder a MySQL."
            return
        fi
        
        # Actualizar el comando de MySQL para usar la contraseña
        mysql_cmd="mysql -u root -p\"$mysql_root_pass\""
    fi
    
    # Crear la base de datos
    print_message "   Creando base de datos $db_name..." "$BLUE"
    if eval "$mysql_cmd -e \"CREATE DATABASE IF NOT EXISTS \\\`$db_name\\\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\""; then
        # Registrar la acción para rollback
        register_action "database_created:$db_name"
        
        # Crear usuario y asignar permisos
        print_message "   Creando usuario $db_user con permisos..." "$BLUE"
        
        # Crear usuario - primero borrar si existe para evitar errores
        eval "$mysql_cmd -e \"DROP USER IF EXISTS '$db_user'@'localhost';\""
        eval "$mysql_cmd -e \"CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';\""
        eval "$mysql_cmd -e \"GRANT ALL PRIVILEGES ON \\\`$db_name\\\`.* TO '$db_user'@'localhost';\""
        eval "$mysql_cmd -e \"FLUSH PRIVILEGES;\""
        
        print_message "✅ Usuario $db_user creado con contraseña: $db_pass" "$GREEN"
        
        # Actualizar el archivo .env con la configuración de la base de datos
        if [ -f "$project_path/.env" ]; then
            print_message "   Actualizando archivo .env con credenciales de base de datos..." "$BLUE"
            
            # Asegurarnos de que estamos usando MySQL (esto ya funcionaba bien)
            sed -i "s/DB_CONNECTION=.*$/DB_CONNECTION=mysql/g" "$project_path/.env"
            
            # CORRECCIÓN: Usar expresiones sed más precisas para manejar líneas comentadas
            
            # DB_HOST: Reemplazar línea con o sin comentario
            sed -i -E 's/^#?[[:space:]]*(DB_HOST=).*$/DB_HOST=127.0.0.1/' "$project_path/.env"
            
            # DB_PORT: Reemplazar línea con o sin comentario
            sed -i -E 's/^#?[[:space:]]*(DB_PORT=).*$/DB_PORT=3306/' "$project_path/.env"
            
            # DB_DATABASE: Reemplazar línea con o sin comentario
            sed -i -E "s/^#?[[:space:]]*(DB_DATABASE=).*$/DB_DATABASE=$db_name/" "$project_path/.env"
            
            # DB_USERNAME: Reemplazar línea con o sin comentario
            sed -i -E "s/^#?[[:space:]]*(DB_USERNAME=).*$/DB_USERNAME=$db_user/" "$project_path/.env"
            
            # DB_PASSWORD: Reemplazar línea con o sin comentario
            sed -i -E "s/^#?[[:space:]]*(DB_PASSWORD=).*$/DB_PASSWORD=$db_pass/" "$project_path/.env"
            
            # Verificar que los cambios se aplicaron correctamente
            if grep -q "DB_CONNECTION=mysql" "$project_path/.env" && \
               grep -q "DB_USERNAME=$db_user" "$project_path/.env" && \
               grep -q "DB_PASSWORD=$db_pass" "$project_path/.env"; then
                print_message "✅ Archivo .env actualizado correctamente." "$GREEN"
            else
                warning_message "No se pudieron aplicar todos los cambios al archivo .env."
                print_message "   Verifica manualmente la configuración en $project_path/.env" "$YELLOW"
            fi
            
            # Verificar si podemos conectarnos con las nuevas credenciales
            if mysql -u "$db_user" -p"$db_pass" -e "USE \`$db_name\`; SELECT 1;" &>/dev/null; then
                print_message "✅ Conexión a la base de datos verificada correctamente." "$GREEN"
            else
                warning_message "No se pudo verificar la conexión con las nuevas credenciales."
                print_message "   Puede que necesites ajustar manualmente la configuración." "$YELLOW"
            fi
        else
            warning_message "No se encontró el archivo .env. Las credenciales de base de datos son:"
            print_message "   DB_CONNECTION: mysql" "$BLUE"
            print_message "   DB_HOST: 127.0.0.1" "$BLUE"
            print_message "   DB_PORT: 3306" "$BLUE"
            print_message "   DB_DATABASE: $db_name" "$BLUE"
            print_message "   DB_USERNAME: $db_user" "$BLUE"
            print_message "   DB_PASSWORD: $db_pass" "$BLUE"
            print_message "   Actualiza manualmente tu archivo .env con esta información." "$YELLOW"
        fi
        
        print_message "✅ Base de datos configurada correctamente." "$GREEN"
    else
        warning_message "No se pudo crear la base de datos. Verifica tus permisos de MySQL."
    fi
}

# Mostrar resumen final
show_summary() {
    local project_name=$1
    local project_path=$2
    local domain=$3
    
    print_message "\n===== RESUMEN DE CONFIGURACIÓN =====" "$GREEN"
    print_message "✅ Proyecto Laravel: $project_name" "$GREEN"
    print_message "✅ Ruta del proyecto: $project_path" "$GREEN"
    print_message "✅ Dominio local: $domain" "$GREEN"
    print_message "✅ Virtual host configurado" "$GREEN"
    print_message "✅ Archivo hosts actualizado" "$GREEN"
    print_message "✅ Permisos configurados" "$GREEN"
    print_message "✅ Xdebug configurado" "$GREEN"
    print_message "✅ Vite configurado" "$GREEN"
    
    print_message "\n==== PRÓXIMOS PASOS ====" "$BLUE"
    print_message "1. Para ejecutar migraciones (base de datos):" "$BLUE"
    print_message "   cd $project_path" "$YELLOW"
    print_message "   php artisan migrate" "$YELLOW"
    print_message "2. Para instalar dependencias de frontend:" "$BLUE"
    print_message "   cd $project_path" "$YELLOW"
    print_message "   npm install" "$YELLOW"
    print_message "3. Para desarrollo con Vite y hot-reload:" "$BLUE"
    print_message "   npm run dev" "$YELLOW"
    print_message "4. Para compilar para producción:" "$BLUE"
    print_message "   npm run build" "$YELLOW"
    print_message "5. Visita http://$domain en tu navegador" "$BLUE"
    print_message "6. ¡Disfruta desarrollando con Laravel! 🚀" "$GREEN"
}

# Punto de entrada principal del script
main() {
    # Si se solicita rollback explícitamente
    if [ "$1" = "--rollback" ]; then
        print_message "Iniciando rollback por solicitud explícita..." "$YELLOW"
        perform_rollback
        exit 0
    fi
    
    # Inicializar el archivo de acciones
    > "$ACTIONS_FILE"
    chmod 666 "$ACTIONS_FILE"
    
    # Mensaje de bienvenida
    print_message "\n==== CONFIGURACIÓN DE ENTORNO PARA PROYECTO LARAVEL ====" "$GREEN"
    print_message "Este script configurará el entorno para un proyecto Laravel existente." "$GREEN"
    print_message "Para crear un nuevo proyecto Laravel, primero ejecuta: composer create-project laravel/laravel nombre-proyecto" "$YELLOW"
    
    # Verificar permisos de root
    check_root
    
    # Verificar dependencias
    check_dependencies
    
    # Obtener información del proyecto
    get_project_info
    
    # Configurar permisos
    configure_permissions "$project_path"
    
    # Configurar archivo .env
    configure_env "$project_path" "$project_name" "$domain"
    
    # Configurar Vite
    configure_vite "$project_path" "$domain"
    
    # Configurar hosts
    configure_hosts "$domain"
    
    # Configurar virtual host
    configure_vhost "$project_path" "$domain"
    
    # Configurar Xdebug
    configure_xdebug
    
    # Crear base de datos
    create_database "$project_name" "$project_path" "$domain"
    
    # Mostrar resumen
    show_summary "$project_name" "$project_path" "$domain"
}

# Comprobar si se solicita ayuda
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Uso: $0 [OPCIÓN]"
    echo ""
    echo "Opciones:"
    echo "  --rollback    Deshacer todas las acciones realizadas por este script"
    echo "  --help, -h    Mostrar esta ayuda"
    echo ""
    echo "Ejemplo: $0"
    echo "         $0 --rollback"
    exit 0
fi

# Ejecutar el script principal
main "$@"
