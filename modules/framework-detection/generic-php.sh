#!/bin/bash

# Generic PHP project detector and setup

# Detect if a project is a generic PHP project
detect_generic_php() {
    # This always returns true as a fallback
    # We consider any directory a potential PHP project
    return 0
}

# Setup for generic PHP projects
setup_generic_php() {
    local project_path=$1
    local project_name=$2

    print_message "🌐 Configurando proyecto PHP genérico..." "$BLUE"

    # Global variable to store the selected public directory
    PUBLIC_DIR=""

    # Check if the project directory is empty
    if is_project_empty "$project_path"; then
        print_message "   El directorio del proyecto está vacío." "$BLUE"

        # Offer to create a recommended directory structure
        read -p "¿Quieres crear una estructura recomendada para un proyecto PHP? (s/n): " create_structure
        if [[ $create_structure == "s" || $create_structure == "S" ]]; then
            create_php_structure "$project_path" "$project_name"
        else
            # If no structure is created, use the root as public dir
            PUBLIC_DIR="$project_path"
            print_message "   Se usará el directorio raíz como directorio público." "$BLUE"
        fi
    else
        print_message "   El directorio del proyecto ya contiene archivos." "$BLUE"

        # Let the user select which directory should be the public directory
        select_public_directory "$project_path"
    fi

    # Configure permissions for generic PHP
    configure_generic_php_permissions "$project_path"

    print_message "✅ Configuración de proyecto PHP genérico completada." "$GREEN"
    print_message "   Directorio público: $PUBLIC_DIR" "$GREEN"

    return 0
}

# Create a recommended PHP project structure
create_php_structure() {
    local project_path=$1
    local project_name=$2

    print_message "   Creando estructura de directorios recomendada..." "$BLUE"

    # Create directories
    mkdir -p "$project_path/public"
    mkdir -p "$project_path/public/css"
    mkdir -p "$project_path/public/js"
    mkdir -p "$project_path/public/images"
    mkdir -p "$project_path/src"
    mkdir -p "$project_path/config"
    mkdir -p "$project_path/templates"
    mkdir -p "$project_path/vendor"

    # Create basic index.php with "Hello World"
    cat > "$project_path/public/index.php" << EOF
<?php
/**
 * Main entry point for $project_name
 */

// Include any necessary files
// require_once __DIR__ . '/../vendor/autoload.php';
// require_once __DIR__ . '/../config/config.php';

// Simple "Hello World" output
echo '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$project_name</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <div class="container">
        <h1>¡Hola, Mundo!</h1>
        <p>Bienvenido a $project_name</p>
    </div>
    <script src="js/script.js"></script>
</body>
</html>';
EOF

    # Create basic CSS file
    cat > "$project_path/public/css/style.css" << EOF
body {
    font-family: Arial, sans-serif;
    line-height: 1.6;
    color: #333;
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
}

.container {
    border: 1px solid #ddd;
    border-radius: 5px;
    padding: 20px;
    margin-top: 30px;
    background-color: #f9f9f9;
}

h1 {
    color: #2c3e50;
}
EOF

    # Create basic JS file
    cat > "$project_path/public/js/script.js" << EOF
// Basic JavaScript file
document.addEventListener('DOMContentLoaded', function() {
    console.log('¡El documento está listo!');
});
EOF

    # Create example configuration file
    cat > "$project_path/config/config.php" << EOF
<?php
/**
 * Configuration file for $project_name
 */

return [
    'app' => [
        'name' => '$project_name',
        'debug' => true,
    ],
    'database' => [
        'host' => 'localhost',
        'name' => '${project_name}_db',
        'user' => '${project_name}_user',
        'pass' => 'password',
    ],
];
EOF

    # Set correct permissions
    find "$project_path" -type d -exec chmod 755 {} \;
    find "$project_path" -type f -exec chmod 644 {} \;

    # Set the public directory
    PUBLIC_DIR="$project_path/public"

    print_message "   ✅ Estructura de directorios creada correctamente." "$GREEN"
    print_message "   ℹ️ Directorio público: $PUBLIC_DIR" "$BLUE"

    return 0
}

# Let the user select which directory should be the public directory
select_public_directory() {
    local project_path=$1

    print_message "   Seleccionando directorio público para el proyecto..." "$BLUE"

    # Check for common public directory names
    local common_dirs=("public" "public_html" "www" "htdocs" "web")
    local found_dirs=()

    # Add the project root as an option
    found_dirs+=("$project_path (directorio raíz)")

    # Find existing directories that might be public directories
    for dir in "${common_dirs[@]}"; do
        if [ -d "$project_path/$dir" ]; then
            found_dirs+=("$project_path/$dir")
        fi
    done

    # List other first-level directories in the project
    for dir in "$project_path"/*; do
        if [ -d "$dir" ] && [[ ! " ${found_dirs[@]} " =~ " $dir " ]]; then
            found_dirs+=("$dir")
        fi
    done

    # If no subdirectories are found (except those already in found_dirs)
    if [ ${#found_dirs[@]} -eq 1 ]; then
        print_message "   No se encontraron subdirectorios. Se usará el directorio raíz como público." "$YELLOW"
        PUBLIC_DIR="$project_path"
        return 0
    fi

    # Ask the user to select which directory should be the public directory
    print_message "   Selecciona el directorio que debe ser accesible públicamente:" "$YELLOW"

    select dir in "${found_dirs[@]}"; do
        if [ -n "$dir" ]; then
            # Extract just the directory path (remove the comment part if present)
            PUBLIC_DIR=$(echo "$dir" | sed 's/ (directorio raíz)//')
            print_message "   ✅ Directorio público seleccionado: $PUBLIC_DIR" "$GREEN"
            return 0
        else
            print_message "   ❌ Selección inválida. Inténtalo de nuevo." "$RED"
        fi
    done

    return 1
}

# Configure permissions for generic PHP project
configure_generic_php_permissions() {
    local project_path=$1
    local www_user="www-data"  # Apache user on Ubuntu

    print_message "   Configurando permisos para proyecto PHP..." "$BLUE"

    # Set basic permissions
    find "$project_path" -type d -exec chmod 755 {} \;
    find "$project_path" -type f -exec chmod 644 {} \;

    # Set ownership
    chown -R "$REAL_USER":"$REAL_USER" "$project_path"

    # If we have a specific public directory that's not the root, set www-data as group
    if [ "$PUBLIC_DIR" != "$project_path" ]; then
        chgrp -R "$www_user" "$PUBLIC_DIR"
    fi

    print_message "   ✅ Permisos configurados" "$GREEN"
}