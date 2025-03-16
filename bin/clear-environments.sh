#!/bin/bash

# Script de Limpieza de Entornos
# Reemplaza el anterior sistema de rollback, siguiendo principios SOLID
# Autor: Jose Antonio Pino
# Fecha: $(date +%Y-%m-%d)

# Obtener el directorio donde se encuentra el script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Importar funciones compartidas
source "$SCRIPT_DIR/functions.sh"

# Colores para mensajes (ya definidos en functions.sh pero los mantenemos por si se ejecuta independientemente)
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Variables globales
REAL_USER=""
REAL_HOME=""
domains=()

# Base de directorios a comprobar (movido fuera de las funciones para ser global)
directories_to_check=(
    "$REAL_HOME/www"
    "$REAL_HOME/www/laravel"
    "/var/www"
    "/var/www/html"
)

# Verificar si se ejecuta como root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_message "Este script de limpieza debe ejecutarse con sudo para modificar archivos del sistema." "$RED"
        exit 1
    fi
}

# Obtener el usuario real
get_real_user() {
    REAL_USER=${SUDO_USER:-$USER}
    REAL_HOME=$(eval echo ~$REAL_USER)

    print_message "👤 Usuario real: $REAL_USER" "$BLUE"
    print_message "🏠 Directorio home: $REAL_HOME" "$BLUE"

    # Actualizar los directorios con el home real
    directories_to_check[0]="$REAL_HOME/www"
    directories_to_check[1]="$REAL_HOME/www/laravel"
}

# Función para solicitar y procesar la lista de dominios
get_domains() {
    print_message "Introduce los nombres de dominio a limpiar (sin el .test)." "$BLUE"
    print_message "Puedes separar múltiples dominios con espacios o comas." "$BLUE"
    print_message "Ejemplo: prueba1 prueba2 prueba3" "$YELLOW"
    print_message "         o bien: prueba1,prueba2,prueba3" "$YELLOW"
    read -p "> " domain_input

    # Si no se proporciona entrada, ofrecer el uso del rango prueba1-prueba26
    if [ -z "$domain_input" ]; then
        print_message "No has introducido dominios. ¿Quieres limpiar prueba1 hasta prueba26? (s/n): " "$YELLOW"
        read -p "> " use_default
        if [[ $use_default == "s" || $use_default == "S" ]]; then
            domains=()
            for i in {1..26}; do
                domains+=("prueba$i")
            done
            return
        else
            print_message "Operación cancelada. No se especificaron dominios." "$RED"
            exit 0
        fi
    fi

    # Reemplazar comas por espacios y luego dividir por espacios
    domain_input=${domain_input//,/ }

    # Convertir la entrada en un array
    IFS=' ' read -ra domains <<< "$domain_input"

    # Verificar que se obtuvieron dominios
    if [ ${#domains[@]} -eq 0 ]; then
        print_message "No se pudo procesar la lista de dominios. Operación cancelada." "$RED"
        exit 1
    fi

    # Mostrar los dominios que se procesarán
    print_message "Se procesarán los siguientes dominios:" "$BLUE"
    for domain in "${domains[@]}"; do
        # Añadir .test si no está presente
        if [[ ! "$domain" =~ \. ]]; then
            domain="${domain}.test"
        fi
        print_message "  - $domain" "$YELLOW"
    done

    # Confirmar que la lista es correcta
    print_message "¿Es correcta esta lista? (s/n): " "$YELLOW"
    read -p "> " confirm_domains
    if [[ $confirm_domains != "s" && $confirm_domains != "S" ]]; then
        print_message "Operación cancelada. Por favor, ejecuta el script nuevamente." "$RED"
        exit 0
    fi
}

# Limpiar hosts virtuales de Apache
clean_apache_vhosts() {
    print_message "🔄 Eliminando hosts virtuales de Apache..." "$BLUE"

    for domain in "${domains[@]}"; do
        # Añadir .test si no está presente
        if [[ ! "$domain" =~ \. ]]; then
            domain_with_suffix="${domain}.test"
        else
            domain_with_suffix="${domain}"
        fi

        if [ -f "/etc/apache2/sites-available/${domain_with_suffix}.conf" ]; then
            print_message "   Eliminando host virtual: ${domain_with_suffix}" "$BLUE"
            a2dissite "${domain_with_suffix}.conf" > /dev/null 2>&1
            rm -f "/etc/apache2/sites-available/${domain_with_suffix}.conf"
        else
            print_message "   Host virtual no encontrado: ${domain_with_suffix}" "$YELLOW"
        fi
    done

    # Reiniciar Apache
    print_message "   Reiniciando Apache..." "$BLUE"
    systemctl restart apache2 > /dev/null 2>&1
    print_message "✅ Hosts virtuales de Apache limpiados." "$GREEN"
}

# Limpiar archivo /etc/hosts
clean_hosts_file() {
    print_message "🔄 Limpiando archivo /etc/hosts..." "$BLUE"

    # Crear copia de seguridad del archivo hosts
    backup_file="/etc/hosts.bak.$(date +%Y%m%d%H%M%S)"
    cp /etc/hosts "$backup_file"
    print_message "   Creada copia de seguridad del archivo hosts: $backup_file" "$BLUE"

    for domain in "${domains[@]}"; do
        # Añadir .test si no está presente
        if [[ ! "$domain" =~ \. ]]; then
            domain_with_suffix="${domain}.test"
        else
            domain_with_suffix="${domain}"
        fi

        if grep -q "$domain_with_suffix" /etc/hosts; then
            print_message "   Eliminando entrada para: ${domain_with_suffix}" "$BLUE"
            sed -i "/127.0.0.1\s*${domain_with_suffix}/d" /etc/hosts
        else
            print_message "   Entrada no encontrada en hosts: ${domain_with_suffix}" "$YELLOW"
        fi
    done

    print_message "✅ Archivo hosts limpiado." "$GREEN"
}

# Eliminar directorios de proyectos
clean_project_directories() {
    print_message "🔄 Eliminando directorios de proyectos..." "$BLUE"

    for domain in "${domains[@]}"; do
        # Eliminar sufijo para obtener el nombre base
        domain_base="${domain%%.*}"

        for base_dir in "${directories_to_check[@]}"; do
            project_dir="$base_dir/$domain_base"

            if [ -d "$project_dir" ]; then
                print_message "   ¿Eliminar directorio: $project_dir? (s/n)" "$YELLOW"
                read -p "> " confirm_delete

                if [[ $confirm_delete == "s" || $confirm_delete == "S" ]]; then
                    print_message "   Eliminando directorio: $project_dir" "$BLUE"
                    rm -rf "$project_dir"
                    print_message "   ✅ Directorio eliminado" "$GREEN"
                else
                    print_message "   Se omite la eliminación del directorio $project_dir" "$YELLOW"
                fi
            fi
        done
    done

    print_message "✅ Directorios de proyectos procesados." "$GREEN"
}

# Limpiar bases de datos
clean_databases() {
    print_message "🔄 Limpiando bases de datos..." "$BLUE"

    # Usar el nuevo sistema modular
    source "$PROJECT_ROOT/modules/database/clean-db.sh"

    for domain in "${domains[@]}"; do
        # Eliminar sufijo para obtener el nombre base
        domain_base="${domain%%.*}"

        # También pasar la ruta del proyecto si está disponible
        local project_path=""
        for dir in "${directories_to_check[@]}"; do
            if [ -d "$dir/$domain_base" ]; then
                project_path="$dir/$domain_base"
                break
            fi
        done

        # Llamar a la función mejorada
        clean_database_enhanced "$domain_base" "$project_path"
    done

    print_message "✅ Limpieza de bases de datos completada." "$GREEN"
}

# Verificar si quedan otros entornos
check_other_environments() {
    print_message "\n🔍 Verificando si existen otros entornos de prueba..." "$BLUE"

    # Verificar hosts virtuales
    other_vhosts=$(find /etc/apache2/sites-available -name "*.test.conf" -o -name "*.local.conf" | wc -l)
    if [ $other_vhosts -gt 0 ]; then
        print_message "   ⚠️ Se encontraron $other_vhosts hosts virtuales adicionales que podrían ser entornos de prueba." "$YELLOW"
        print_message "   Puedes listarlos con: ls /etc/apache2/sites-available/*.test.conf /etc/apache2/sites-available/*.local.conf 2>/dev/null" "$YELLOW"
    else
        print_message "   ✅ No se encontraron otros hosts virtuales." "$GREEN"
    fi

    # Verificar entradas en hosts
    other_hosts=$(grep -c ".test\|.local" /etc/hosts)
    if [ $other_hosts -gt 0 ]; then
        print_message "   ⚠️ Se encontraron $other_hosts entradas en /etc/hosts que podrían ser entornos de prueba." "$YELLOW"
        print_message "   Puedes listarlas con: grep '.test\|.local' /etc/hosts" "$YELLOW"
    else
        print_message "   ✅ No se encontraron otras entradas en /etc/hosts." "$GREEN"
    fi
}

# Función principal - punto de entrada
main() {
    # Encabezado del script
    print_message "\n🧹 LIMPIEZA DE ENTORNOS DE DESARROLLO" "$GREEN"
    print_message "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖" "$GREEN"

    # Verificar si se ejecuta como root
    check_root

    # Obtener usuario real
    get_real_user

    # Solicitar la lista de dominios
    get_domains

    # Pedir confirmación general
    print_message "\n⚠️ ADVERTENCIA: ¡Esto eliminará TODOS los rastros de los entornos seleccionados!" "$YELLOW"
    print_message "Esto incluye:" "$YELLOW"
    print_message "  - Hosts virtuales de Apache" "$YELLOW"
    print_message "  - Entradas en /etc/hosts" "$YELLOW"
    print_message "  - Directorios de proyectos" "$YELLOW"
    print_message "  - Bases de datos (MySQL, PostgreSQL, SQLite, SQL Server, MongoDB)" "$YELLOW"
    read -p "¿Estás seguro de que quieres continuar? (s/n): " confirm
    if [[ $confirm != "s" && $confirm != "S" ]]; then
        print_message "Operación cancelada." "$BLUE"
        exit 0
    fi

    # Ejecutar limpieza
    clean_apache_vhosts
    clean_hosts_file
    clean_project_directories
    clean_databases

    # Preguntar si quiere verificar otros entornos
    read -p "¿Quieres verificar si existen otros entornos de prueba? (s/n): " check_others
    if [[ $check_others == "s" || $check_others == "S" ]]; then
        check_other_environments
    fi

    print_message "\n✨ ¡Limpieza completada con éxito!" "$GREEN"
    print_message "👋 ¡Gracias por usar el script de limpieza!" "$GREEN"
}

# Mostrar ayuda si se solicita
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Uso: $0 [OPCIÓN]"
    echo ""
    echo "Opciones:"
    echo "  --help, -h    Mostrar esta ayuda"
    echo ""
    echo "Este script limpia entornos de desarrollo creados con setup-environment.sh"
    echo "Elimina hosts virtuales, entradas en /etc/hosts, directorios de proyectos y bases de datos."
    echo ""
    echo "Ejemplo: $0"
    exit 0
fi

# Ejecutar función principal
main "$@"