#!/bin/bash

# Script de Limpieza de Entornos de Prueba Laravel
# Este script elimina todos los rastros de entornos de prueba proporcionados por el usuario

# Colores para mensajes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Función para imprimir mensajes coloreados
print_message() {
    echo -e "${2}${1}${NC}"
}

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    print_message "Este script de limpieza debe ejecutarse con sudo para modificar archivos del sistema." "$RED"
    exit 1
fi

# Obtener el nombre de usuario real (si se ejecuta con sudo)
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

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
        print_message "  - $domain.test" "$YELLOW"
    done
    
    # Confirmar que la lista es correcta
    print_message "¿Es correcta esta lista? (s/n): " "$YELLOW"
    read -p "> " confirm_domains
    if [[ $confirm_domains != "s" && $confirm_domains != "S" ]]; then
        print_message "Operación cancelada. Por favor, ejecuta el script nuevamente." "$RED"
        exit 0
    fi
}

# Solicitar la lista de dominios
get_domains

# Pedir confirmación general
print_message "\n⚠️ ADVERTENCIA: ¡Esto eliminará TODOS los rastros de los entornos seleccionados!" "$YELLOW"
print_message "Esto incluye:" "$YELLOW"
print_message "  - Hosts virtuales de Apache" "$YELLOW"
print_message "  - Entradas en /etc/hosts" "$YELLOW"
print_message "  - Directorios de proyectos en ~/www/laravel/" "$YELLOW"
print_message "  - Bases de datos y usuarios de MySQL" "$YELLOW"
read -p "¿Estás seguro de que quieres continuar? (s/n): " confirm
if [[ $confirm != "s" && $confirm != "S" ]]; then
    print_message "Operación cancelada." "$BLUE"
    exit 0
fi

# 1. Limpiar hosts virtuales de Apache
print_message "🔄 Eliminando hosts virtuales de Apache..." "$BLUE"
for domain in "${domains[@]}"; do
    domain_with_suffix="${domain}.test"
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

# 2. Limpiar archivo /etc/hosts
print_message "🔄 Limpiando archivo /etc/hosts..." "$BLUE"
backup_file="/etc/hosts.bak.$(date +%Y%m%d%H%M%S)"
cp /etc/hosts "$backup_file"
print_message "   Creada copia de seguridad del archivo hosts: $backup_file" "$BLUE"

for domain in "${domains[@]}"; do
    domain_with_suffix="${domain}.test"
    if grep -q "$domain_with_suffix" /etc/hosts; then
        print_message "   Eliminando entrada para: ${domain_with_suffix}" "$BLUE"
        sed -i "/127.0.0.1\s*${domain_with_suffix}/d" /etc/hosts
    else
        print_message "   Entrada no encontrada en hosts: ${domain_with_suffix}" "$YELLOW"
    fi
done
print_message "✅ Archivo hosts limpiado." "$GREEN"

# 3. Eliminar directorios de proyectos
print_message "🔄 Eliminando directorios de proyectos..." "$BLUE"
project_base_dir="$REAL_HOME/www/laravel"

if [ -d "$project_base_dir" ]; then
    for domain in "${domains[@]}"; do
        project_dir="$project_base_dir/$domain"
        if [ -d "$project_dir" ]; then
            print_message "   Eliminando directorio: $project_dir" "$BLUE"
            rm -rf "$project_dir"
        else
            print_message "   Directorio no encontrado: $project_dir" "$YELLOW"
        fi
    done
    print_message "✅ Directorios de proyectos eliminados." "$GREEN"
else
    print_message "   Directorio base de proyectos no encontrado: $project_base_dir" "$YELLOW"
fi

# 4. Eliminar bases de datos y usuarios de MySQL
print_message "🔄 Limpiando bases de datos y usuarios de MySQL..." "$BLUE"

# Pedir contraseña de root de MySQL
read -sp "Introduce la contraseña de root de MySQL (deja vacío si no hay): " mysql_pwd
echo ""

mysql_cmd="mysql"
if [ -n "$mysql_pwd" ]; then
    mysql_cmd="mysql -u root -p'$mysql_pwd'"
fi

# Probar conexión MySQL
if ! eval "$mysql_cmd -e 'SELECT 1'" > /dev/null 2>&1; then
    print_message "   No se pudo conectar a MySQL. Limpieza de base de datos omitida." "$YELLOW"
else
    for domain in "${domains[@]}"; do
        db_name="$domain"
        db_user="${domain}_user"
        
        # Verificar si la base de datos existe antes de eliminarla
        if eval "$mysql_cmd -e \"SHOW DATABASES LIKE '$db_name'\"" | grep -q "$db_name"; then
            print_message "   Eliminando base de datos: $db_name" "$BLUE"
            eval "$mysql_cmd -e \"DROP DATABASE \\\`$db_name\\\`;\""
        else
            print_message "   Base de datos no encontrada: $db_name" "$YELLOW"
        fi
        
        # Verificar si el usuario existe antes de eliminarlo
        if eval "$mysql_cmd -e \"SELECT User FROM mysql.user WHERE User='$db_user'\"" | grep -q "$db_user"; then
            print_message "   Eliminando usuario MySQL: $db_user" "$BLUE"
            eval "$mysql_cmd -e \"DROP USER IF EXISTS '$db_user'@'localhost';\""
        else
            print_message "   Usuario MySQL no encontrado: $db_user" "$YELLOW"
        fi
    done
    
    # Actualizar privilegios para aplicar cambios
    eval "$mysql_cmd -e \"FLUSH PRIVILEGES;\""
    print_message "✅ Bases de datos y usuarios de MySQL limpiados." "$GREEN"
fi

print_message "\n✨ ¡Limpieza completada con éxito! Todos los rastros de los entornos seleccionados han sido eliminados." "$GREEN"

# Función adicional: verificar si quedan otros entornos de prueba
check_for_other_environments() {
    print_message "\n🔍 Verificando si existen otros entornos de prueba..." "$BLUE"
    
    # Verificar hosts virtuales
    other_vhosts=$(find /etc/apache2/sites-available -name "*.test.conf" -o -name "*.local.conf" | wc -l)
    if [ $other_vhosts -gt 0 ]; then
        print_message "   ⚠️ Se encontraron $other_vhosts hosts virtuales adicionales que podrían ser entornos de prueba." "$YELLOW"
        print_message "   Puedes listarlos con: ls /etc/apache2/sites-available/*.test.conf /etc/apache2/sites-available/*.local.conf 2>/dev/null" "$YELLOW"
    fi
    
    # Verificar entradas en hosts
    other_hosts=$(grep -c ".test\|.local" /etc/hosts)
    if [ $other_hosts -gt 0 ]; then
        print_message "   ⚠️ Se encontraron $other_hosts entradas en /etc/hosts que podrían ser entornos de prueba." "$YELLOW"
        print_message "   Puedes listarlas con: grep '.test\|.local' /etc/hosts" "$YELLOW"
    fi
    
    # Verificar directorios de proyectos
    if [ -d "$project_base_dir" ]; then
        other_projects=$(find "$project_base_dir" -maxdepth 1 -type d | wc -l)
        # Restar 1 para ignorar el directorio base mismo
        other_projects=$((other_projects - 1))
        if [ $other_projects -gt 0 ]; then
            print_message "   ⚠️ Se encontraron $other_projects directorios adicionales en $project_base_dir que podrían ser proyectos." "$YELLOW"
            print_message "   Puedes listarlos con: ls -la $project_base_dir" "$YELLOW"
        fi
    fi
}

# Preguntar si quiere verificar otros entornos
read -p "¿Quieres verificar si existen otros entornos de prueba? (s/n): " check_others
if [[ $check_others == "s" || $check_others == "S" ]]; then
    check_for_other_environments
fi

print_message "\n👋 ¡Gracias por usar el script de limpieza!" "$GREEN"
