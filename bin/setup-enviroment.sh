#!/bin/bash

# Script para configurar entornos de desarrollo PHP/Laravel
# Refactorizado siguiendo principios SOLID
# Autor: Tu nombre
# Fecha: $(date +%Y-%m-%d)

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source shared functions
source "$SCRIPT_DIR/functions.sh"

# Source modules
source "$PROJECT_ROOT/modules/framework-detection/detect.sh"
source "$PROJECT_ROOT/modules/xdebug/configure.sh"

# Global variables
FRAMEWORK_TYPE=""
PUBLIC_DIR=""
PROJECT_PATH=""
PROJECT_NAME=""
DOMAIN=""

# Welcome message
welcome() {
    print_message "\n==== CONFIGURACIÓN DE ENTORNO DE DESARROLLO ====" "$GREEN"
    print_message "Este script configurará un entorno de desarrollo para proyectos PHP en entornos LAMP." "$GREEN"
    print_message "Se detectará automáticamente el tipo de proyecto y se ajustará la configuración." "$GREEN"
}

# Get project information from user
get_project_info() {
    local default_base_path="$REAL_HOME/www"

    # Ask for project name
    while true; do
        read -p "Ingresa el nombre del proyecto: " project_name

        if [ -z "$project_name" ]; then
            warning_message "El nombre del proyecto no puede estar vacío."
        elif [[ ! "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            warning_message "El nombre del proyecto solo puede contener letras, números, guiones y guiones bajos."
        else
            break
        fi
    done

    PROJECT_NAME="$project_name"

    # Default path based on project name
    local default_project_path="$default_base_path/$project_name"

    # Ask for project path
    read -p "Ingresa la ruta completa del proyecto [$default_project_path]: " input_project_path
    PROJECT_PATH=${input_project_path:-$default_project_path}

    # Create project directory if it doesn't exist
    if [ ! -d "$PROJECT_PATH" ]; then
        print_message "   Creando directorio del proyecto: $PROJECT_PATH" "$BLUE"
        mkdir -p "$PROJECT_PATH"
        chown "$REAL_USER":"$REAL_USER" "$PROJECT_PATH"
    fi

    # Ask for domain name
    local default_domain="${PROJECT_NAME}.test"
    read -p "Ingresa el dominio local para el proyecto [$default_domain]: " input_domain
    DOMAIN=${input_domain:-$default_domain}

    # Validate domain format
    if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        warning_message "El dominio contiene caracteres no válidos. Se usará el dominio predeterminado: $default_domain"
        DOMAIN="$default_domain"
    fi

    # Show summary of project information and ask for confirmation
    print_message "\n==== INFORMACIÓN DEL PROYECTO ====" "$GREEN"
    print_message "Nombre del proyecto: $PROJECT_NAME" "$BLUE"
    print_message "Ruta del proyecto: $PROJECT_PATH" "$BLUE"
    print_message "Dominio local: $DOMAIN" "$BLUE"

    read -p "¿Es correcta esta información? (s/n): " confirm
    if [[ $confirm != "s" && $confirm != "S" ]]; then
        error_exit "Operación cancelada por el usuario."
    fi
}

# Setup the environment based on detected framework
setup_environment() {
    # Detect framework type
    print_message "🔍 Detectando tipo de framework..." "$BLUE"
    FRAMEWORK_TYPE=$(detect_framework "$PROJECT_PATH")
    print_message "   ✅ Framework detectado: $FRAMEWORK_TYPE" "$GREEN"

    # Setup based on framework type
    case "$FRAMEWORK_TYPE" in
        "laravel")
            # Set public directory
            PUBLIC_DIR="$PROJECT_PATH/public"

            # Verify it's a valid Laravel project
            if [ ! -f "$PROJECT_PATH/artisan" ] || [ ! -d "$PUBLIC_DIR" ]; then
                warning_message "El proyecto parece estar incompleto. Proseguiremos pero pueden ocurrir errores."
            fi

            # Configure Laravel-specific settings
            source "$PROJECT_ROOT/modules/framework-detection/laravel.sh"
            configure_laravel "$PROJECT_PATH" "$DOMAIN"
            ;;

        # Future framework support can be added here
        # "symfony")
        #    source "$PROJECT_ROOT/modules/framework-detection/symfony.sh"
        #    configure_symfony "$PROJECT_PATH" "$DOMAIN"
        #    PUBLIC_DIR="$PROJECT_PATH/public"
        #    ;;

        # "codeigniter")
        #    source "$PROJECT_ROOT/modules/framework-detection/codeigniter.sh"
        #    configure_codeigniter "$PROJECT_PATH" "$DOMAIN"
        #    PUBLIC_DIR="$PROJECT_PATH/public"
        #    ;;

        *)
            # Generic PHP project
            source "$PROJECT_ROOT/modules/framework-detection/generic-php.sh"
            setup_generic_php "$PROJECT_PATH" "$PROJECT_NAME"

            # PUBLIC_DIR is set by setup_generic_php function
            if [ -z "$PUBLIC_DIR" ]; then
                # Fallback if PUBLIC_DIR wasn't set
                PUBLIC_DIR="$PROJECT_PATH"
                warning_message "No se pudo determinar el directorio público. Usando directorio raíz."
            fi
            ;;
    esac

    # Configure common environment elements
    print_message "\n🔄 Configurando elementos comunes del entorno..." "$BLUE"

    # Configure hosts file
    configure_hosts "$DOMAIN"

    # Configure Apache virtual host
    configure_vhost "$PROJECT_PATH" "$DOMAIN" "$PUBLIC_DIR" "$FRAMEWORK_TYPE"

    # Configure Xdebug
    configure_xdebug "$PHP_VERSION" "$REAL_USER"

    # Create database
    create_database "$PROJECT_NAME" "$PROJECT_PATH" "$DOMAIN" "$FRAMEWORK_TYPE"

    # Show summary
    show_summary "$PROJECT_NAME" "$PROJECT_PATH" "$DOMAIN" "$FRAMEWORK_TYPE" "$PUBLIC_DIR"
}

# Main function - entry point
main() {
    # Print script header
    print_message "\n🚀 APACHE VHOST ORCHESTRATOR" "$GREEN"
    print_message "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖" "$GREEN"

    # Check if running as root
    check_root

    # Get real user
    get_real_user

    # Detect PHP version
    detect_php_version

    # Detect shell
    detect_shell

    # Check dependencies
    check_dependencies

    # Show welcome message
    welcome

    # Get project information
    get_project_info

    # Setup the environment
    setup_environment

    print_message "\n✨ ¡Configuración completada con éxito!" "$GREEN"
    print_message "Tu proyecto está listo en: http://$DOMAIN" "$GREEN"
}

# Show help if requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Uso: $0 [OPCIÓN]"
    echo ""
    echo "Opciones:"
    echo "  --help, -h    Mostrar esta ayuda"
    echo ""
    echo "Para limpiar entornos creados, use el script clear-environments.sh"
    echo ""
    echo "Ejemplo: $0"
    exit 0
fi

# Execute main function
main "$@"