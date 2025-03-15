#!/bin/bash

# Shared functions for setup and cleanup scripts

# Colors for messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No color

# Global variables
REAL_USER=""
REAL_HOME=""
PHP_VERSION=""
SHELL_TYPE=""
RC_FILE=""

# Function to display messages with color
print_message() {
    echo -e "${2}${1}${NC}"
}

# Function to display error messages and exit
error_exit() {
    print_message "ERROR: $1" "$RED"
    exit 1
}

# Function to display warning messages
warning_message() {
    print_message "ADVERTENCIA: $1" "$YELLOW"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "Este script debe ejecutarse con privilegios de superusuario (sudo o root)."
    fi
}

# Get real user (if script is run with sudo)
get_real_user() {
    REAL_USER=${SUDO_USER:-$USER}
    REAL_HOME=$(eval echo ~$REAL_USER)

    print_message "👤 Usuario real: $REAL_USER" "$BLUE"
    print_message "🏠 Directorio home: $REAL_HOME" "$BLUE"
}

# Detect PHP version
detect_php_version() {
    # Try specific PHP versions in descending order
    for version in "8.4" "8.3" "8.2" "8.1" "8.0" "7.4"; do
        if command -v php$version &> /dev/null; then
            PHP_VERSION="$version"
            break
        fi
    done

    # If no specific version was found, try generic php
    if [ -z "$PHP_VERSION" ]; then
        if command -v php &> /dev/null; then
            PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
        else
            PHP_VERSION="8.2" # Default version if detection fails
        fi
    fi

    print_message "🔍 PHP $PHP_VERSION detectado" "$BLUE"
}

# Detect user's shell
detect_shell() {
    USER_SHELL=$(getent passwd $REAL_USER | cut -d: -f7)
    if [[ "$USER_SHELL" == *"zsh"* ]]; then
        RC_FILE="$REAL_HOME/.zshrc"
        SHELL_TYPE="zsh"
        print_message "🔍 zsh detectado - usando $RC_FILE" "$BLUE"
    else
        RC_FILE="$REAL_HOME/.bashrc"
        SHELL_TYPE="bash"
        print_message "🔍 bash detectado - usando $RC_FILE" "$BLUE"
    fi
}

# Check required dependencies
check_dependencies() {
    print_message "⚙️ Verificando dependencias necesarias..." "$BLUE"

    # Check PHP
    if ! command -v php$PHP_VERSION &> /dev/null && ! command -v php &> /dev/null; then
        error_exit "PHP $PHP_VERSION no está instalado. Por favor, instálalo usando:\n sudo add-apt-repository ppa:ondrej/php -y && sudo apt update && sudo apt install php$PHP_VERSION php$PHP_VERSION-cli php$PHP_VERSION-common php$PHP_VERSION-curl php$PHP_VERSION-mbstring php$PHP_VERSION-xml php$PHP_VERSION-zip php$PHP_VERSION-mysql php$PHP_VERSION-bcmath php$PHP_VERSION-gd php$PHP_VERSION-opcache -y"
    fi

    # Check Apache
    if ! command -v apache2ctl &> /dev/null; then
        error_exit "Apache2 no está instalado. Por favor, instálalo usando:\n sudo add-apt-repository ppa:ondrej/apache2 -y && sudo apt update && sudo apt install apache2 libapache2-mod-php$PHP_VERSION -y"
    fi

    print_message "✅ Verificación de dependencias completa." "$GREEN"
}

# Configure hosts file
configure_hosts() {
    local domain=$1

    print_message "🌐 Configurando archivo hosts para dominio: $domain" "$BLUE"

    # Check if domain already exists in /etc/hosts
    if grep -q "$domain" /etc/hosts; then
        warning_message "El dominio ya existe en /etc/hosts."
    else
        # Add domain to hosts file
        echo "127.0.0.1   $domain" >> /etc/hosts
        print_message "✅ Dominio añadido a /etc/hosts." "$GREEN"
    fi
}

# Configure Apache virtual host
configure_vhost() {
    local project_path=$1
    local domain=$2
    local public_dir=$3
    local framework=$4

    print_message "🖥️ Configurando virtual host para: $domain" "$BLUE"

    # Create virtual host configuration file
    local vhost_file="/etc/apache2/sites-available/${domain}.conf"

    # Detect if php-fpm is installed and use correct version
    local fpm_config=""
    if [ -S "/var/run/php/php${PHP_VERSION}-fpm.sock" ]; then
        fpm_config="<FilesMatch \\.php\$>
        SetHandler \"proxy:unix:/var/run/php/php${PHP_VERSION}-fpm.sock|fcgi://localhost\"
    </FilesMatch>"
    fi

    # Create virtual host configuration based on framework
    cat > "$vhost_file" << EOF
<VirtualHost *:80>
    ServerName ${domain}
    DocumentRoot ${public_dir}

    <Directory ${public_dir}>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${domain}-error.log
    CustomLog \${APACHE_LOG_DIR}/${domain}-access.log combined

    ${fpm_config}
</VirtualHost>
EOF

    # Enable the site
    a2ensite "${domain}.conf" > /dev/null 2>&1

    # Enable required modules
    a2enmod rewrite > /dev/null 2>&1

    # Enable proxy_fcgi if available and php-fpm is installed
    if [ -n "$fpm_config" ] && apache2ctl -M 2>/dev/null | grep -q "proxy_fcgi_module"; then
        a2enmod proxy_fcgi > /dev/null 2>&1
    fi

    # Restart Apache
    systemctl restart apache2

    print_message "✅ Virtual host configurado correctamente." "$GREEN"
}

# Create database for the project
create_database() {
    local project_name=$1
    local project_path=$2
    local domain=$3
    local framework=$4

    # Ask if user wants to create a database
    read -p "¿Quieres crear una base de datos para este proyecto? (s/n): " create_db
    if [[ $create_db != "s" && $create_db != "S" ]]; then
        return
    fi

    # Use project name as database name
    local db_name="${project_name}"
    local db_user="${project_name}_user"
    local db_pass="password123"  # Simple password for local development

    print_message "🗄️ Creando base de datos: $db_name" "$BLUE"

    # Check if MySQL is installed
    if ! command -v mysql &> /dev/null; then
        warning_message "MySQL no está instalado. Saltando creación de base de datos."
        return
    fi

    # Ask for MySQL root credentials if needed
    local mysql_root_pass=""
    local mysql_cmd="mysql"

    # Try first without password
    if ! mysql -u root -e "SELECT 1" &>/dev/null; then
        print_message "Se requiere contraseña para el usuario root de MySQL." "$YELLOW"
        read -sp "Introduce la contraseña de root para MySQL: " mysql_root_pass
        echo ""

        # Test if password works
        if ! mysql -u root -p"$mysql_root_pass" -e "SELECT 1" &>/dev/null; then
            warning_message "Contraseña incorrecta. No se puede acceder a MySQL."
            return
        fi

        # Update MySQL command to use password
        mysql_cmd="mysql -u root -p\"$mysql_root_pass\""
    fi

    # Create database
    print_message "   Creando base de datos $db_name..." "$BLUE"
    if eval "$mysql_cmd -e \"CREATE DATABASE IF NOT EXISTS \\\`$db_name\\\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\""; then
        # Create user and assign privileges
        print_message "   Creando usuario $db_user con permisos..." "$BLUE"

        # Drop user if exists to avoid errors
        eval "$mysql_cmd -e \"DROP USER IF EXISTS '$db_user'@'localhost';\""
        eval "$mysql_cmd -e \"CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';\""
        eval "$mysql_cmd -e \"GRANT ALL PRIVILEGES ON \\\`$db_name\\\`.* TO '$db_user'@'localhost';\""
        eval "$mysql_cmd -e \"FLUSH PRIVILEGES;\""

        print_message "✅ Usuario $db_user creado con contraseña: $db_pass" "$GREEN"

        # Update .env file for Laravel
        if [ "$framework" == "laravel" ] && [ -f "$project_path/.env" ]; then
            print_message "   Actualizando archivo .env con credenciales de base de datos..." "$BLUE"

            # Use precise sed expressions to handle commented lines
            sed -i -E 's/^#?[[:space:]]*(DB_CONNECTION=).*$/DB_CONNECTION=mysql/' "$project_path/.env"
            sed -i -E 's/^#?[[:space:]]*(DB_HOST=).*$/DB_HOST=127.0.0.1/' "$project_path/.env"
            sed -i -E 's/^#?[[:space:]]*(DB_PORT=).*$/DB_PORT=3306/' "$project_path/.env"
            sed -i -E "s/^#?[[:space:]]*(DB_DATABASE=).*$/DB_DATABASE=$db_name/" "$project_path/.env"
            sed -i -E "s/^#?[[:space:]]*(DB_USERNAME=).*$/DB_USERNAME=$db_user/" "$project_path/.env"
            sed -i -E "s/^#?[[:space:]]*(DB_PASSWORD=).*$/DB_PASSWORD=$db_pass/" "$project_path/.env"

            print_message "✅ Archivo .env actualizado con credenciales de base de datos." "$GREEN"
        } else {
            print_message "✅ Base de datos creada. Credenciales:" "$GREEN"
            print_message "   DB_HOST: 127.0.0.1" "$BLUE"
            print_message "   DB_PORT: 3306" "$BLUE"
            print_message "   DB_DATABASE: $db_name" "$BLUE"
            print_message "   DB_USERNAME: $db_user" "$BLUE"
            print_message "   DB_PASSWORD: $db_pass" "$BLUE"
        }

        print_message "✅ Base de datos configurada correctamente." "$GREEN"
    else
        warning_message "No se pudo crear la base de datos. Verifica tus permisos de MySQL."
    fi
}

# Show final summary with next steps
show_summary() {
    local project_name=$1
    local project_path=$2
    local domain=$3
    local framework=$4
    local public_dir=$5

    print_message "\n===== RESUMEN DE CONFIGURACIÓN =====" "$GREEN"
    print_message "✅ Nombre del proyecto: $project_name" "$GREEN"
    print_message "✅ Ruta del proyecto: $project_path" "$GREEN"
    print_message "✅ Directorio público: $public_dir" "$GREEN"
    print_message "✅ Dominio local: $domain" "$GREEN"
    print_message "✅ Framework: $framework" "$GREEN"

    print_message "\n==== PRÓXIMOS PASOS ====" "$BLUE"

    # Framework-specific next steps
    if [ "$framework" == "laravel" ]; then
        print_message "1. Para ejecutar migraciones:" "$BLUE"
        print_message "   cd $project_path" "$YELLOW"
        print_message "   php artisan migrate" "$YELLOW"
        print_message "2. Para instalar dependencias frontend:" "$BLUE"
        print_message "   cd $project_path" "$YELLOW"
        print_message "   npm install" "$YELLOW"
        print_message "3. Para desarrollo con Vite y hot-reload:" "$BLUE"
        print_message "   npm run dev" "$YELLOW"
    else
        print_message "1. Comienza a desarrollar tu aplicación PHP en:" "$BLUE"
        print_message "   $public_dir" "$YELLOW"
        print_message "2. Para usar Composer (si lo necesitas):" "$BLUE"
        print_message "   cd $project_path" "$YELLOW"
        print_message "   composer init" "$YELLOW"
    fi

    print_message "4. Visita http://$domain en tu navegador" "$BLUE"
    print_message "5. ¡Disfruta desarrollando! 🚀" "$GREEN"

    print_message "\n==== PARA LIMPIAR ESTE ENTORNO ====" "$YELLOW"
    print_message "Si necesitas eliminar este entorno, usa el script clear-environments.sh:" "$YELLOW"
    print_message "   sudo $(dirname "$(readlink -f "$0")")/clear-environments.sh" "$YELLOW"
    print_message "Y especifica el dominio $domain cuando se solicite." "$YELLOW"
}