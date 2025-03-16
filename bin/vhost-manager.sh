#!/bin/bash

# VHOST Manager - Punto de entrada unificado para Apache VHOST Orchestrator
# Autor: Jose Antonio Pino
# Fecha: $(date +%Y-%m-%d)

# Obtener el directorio donde se encuentra el script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Importar funciones compartidas
source "$SCRIPT_DIR/functions.sh"

# Función para mostrar la introducción
show_intro() {
    print_message "\n🚀 APACHE VHOST ORCHESTRATOR" "$GREEN"
    print_message "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖" "$GREEN"
    print_message "Sistema de gestión de entornos de desarrollo web" "$BLUE"
    print_message "Optimizado para proyectos PHP y Laravel" "$BLUE"
}

# Función para mostrar el menú principal
show_menu() {
    print_message "\n📋 ¿Qué acción deseas realizar?" "$GREEN"
    print_message "1. Configurar un nuevo entorno de desarrollo" "$YELLOW"
    print_message "2. Limpiar entornos existentes" "$YELLOW"
    print_message "3. Salir" "$YELLOW"

    read -p "Selecciona una opción [1-3]: " option

    case $option in
        1)
            # Llamar al script de configuración
            print_message "\n🔧 Iniciando configuración de nuevo entorno..." "$BLUE"
            "$SCRIPT_DIR/setup-environment.sh" "$@"
            ;;
        2)
            # Llamar al script de limpieza
            print_message "\n🧹 Iniciando limpieza de entornos..." "$BLUE"
            "$SCRIPT_DIR/clear-environments.sh" "$@"
            ;;
        3)
            print_message "\n👋 ¡Gracias por usar Apache VHOST Orchestrator!" "$GREEN"
            exit 0
            ;;
        *)
            print_message "\n❌ Opción no válida. Por favor, selecciona una opción entre 1 y 3." "$RED"
            show_menu
            ;;
    esac
}

# Función para mostrar ayuda
show_help() {
    echo "Apache VHOST Orchestrator - Sistema de gestión de entornos de desarrollo"
    echo ""
    echo "Uso: $0 [OPCIÓN]"
    echo ""
    echo "Opciones:"
    echo "  --setup          Ir directamente a la configuración de nuevo entorno"
    echo "  --clean          Ir directamente a la limpieza de entornos"
    echo "  --help, -h       Mostrar esta ayuda"
    echo ""
    echo "Sin opciones, muestra un menú interactivo para seleccionar la acción deseada."
    echo ""
    echo "Ejemplos:"
    echo "  $0               # Muestra el menú interactivo"
    echo "  $0 --setup       # Inicia directamente la configuración de entorno"
    echo "  $0 --clean       # Inicia directamente la limpieza de entornos"
}

# Función principal - punto de entrada
main() {
    # Verificar si se ejecuta como root
    check_root

    # Procesar argumentos de línea de comandos
    if [ $# -gt 0 ]; then
        case "$1" in
            --setup)
                shift
                "$SCRIPT_DIR/setup-environment.sh" "$@"
                exit $?
                ;;
            --clean)
                shift
                "$SCRIPT_DIR/clear-environments.sh" "$@"
                exit $?
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_message "Opción desconocida: $1" "$RED"
                show_help
                exit 1
                ;;
        esac
    else
        # Sin argumentos, mostrar interfaz interactiva
        show_intro
        show_menu "$@"
    fi
}

# Ejecutar función principal
main "$@"