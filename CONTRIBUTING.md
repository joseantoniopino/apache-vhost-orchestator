# 🤝 Contribuyendo al Apache VHOST Orchestrator

<p align="center">
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome">
  <img src="https://img.shields.io/badge/bash-5.1%2B-brightgreen" alt="Bash 5.1+">
  <img src="https://img.shields.io/badge/Apache-2.4%2B-red" alt="Apache 2.4+">
</p>

---

**🇪🇸 Español** | [🇬🇧 English](#-contributing-to-apache-vhost-orchestrator)

¡Gracias por tu interés en mejorar Apache VHOST Orchestrator! Este documento te guiará a través del proceso de contribución, desde la configuración de tu entorno hasta la presentación de tu Pull Request.

## 📋 Índice
- [Primeros pasos](#-primeros-pasos)
- [Proceso de contribución](#-proceso-de-contribución)
- [Convenciones de código](#-convenciones-de-código)
- [Estructura del proyecto](#-estructura-del-proyecto)
- [Ampliando la funcionalidad](#-ampliando-la-funcionalidad)
- [Proceso de revisión](#-proceso-de-revisión)

## 🚀 Primeros pasos

### Prerrequisitos
Para trabajar en este proyecto, necesitarás:
- Linux (Ubuntu/Debian recomendado)
- Git
- Apache 2.4+
- PHP 7.4+ (preferiblemente 8.x)
- Al menos uno de estos motores de base de datos (para pruebas):
  - MySQL/MariaDB
  - PostgreSQL
  - SQLite
  - SQL Server
  - MongoDB
- Bash 5.1+

### Configuración del entorno
1. **Fork del repositorio**
   - Haz click en el botón "Fork" en la parte superior derecha de la página de GitHub

2. **Clona tu fork localmente**
   ```bash
   git clone https://github.com/TU-USUARIO/apache-vhost-orchestrator.git
   cd apache-vhost-orchestrator
   ```

3. **Configura los permisos de ejecución**
   ```bash
   chmod +x bin/*.sh
   chmod +x modules/*/*.sh
   chmod +x modules/database/engines/*.sh
   ```

4. **Configura el repositorio upstream (opcional pero recomendado)**
   ```bash
   git remote add upstream https://github.com/joseantoniopino/apache-vhost-orchestrator.git
   ```

## 🔄 Proceso de contribución

1. **Sincroniza tu fork** (si ya ha pasado tiempo desde que lo creaste)
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. **Crea una rama para tu contribución**
   ```bash
   git checkout -b nombre-descriptivo-de-tu-rama
   ```
   Usa un nombre descriptivo relacionado con tu contribución, por ejemplo:
   - `feature/soporte-symfony`
   - `feature/soporte-oracle`
   - `fix/correccion-permisos-xdebug`
   - `docs/mejora-documentacion-modulos`

3. **Realiza tus cambios**
   - Implementa los cambios siguiendo las [convenciones de código](#-convenciones-de-código)
   - Asegúrate de que tu código sigue los principios SOLID

4. **Prueba tus cambios**
   - Ejecuta el script en tu entorno local para asegurarte de que funciona correctamente
   - Verifica que no rompe ninguna funcionalidad existente

5. **Commit de tus cambios**
   ```bash
   git add .
   git commit -m "Descripción clara y concisa de tus cambios"
   ```
   - Utiliza mensajes de commit descriptivos
   - Usa verbos en imperativo (ej: "Añade soporte para...", no "Añadido soporte para...")

6. **Push a tu fork**
   ```bash
   git push origin nombre-descriptivo-de-tu-rama
   ```

7. **Crea un Pull Request**
   - Ve a la página de tu fork en GitHub
   - Haz click en "Compare & pull request"
   - Proporciona una descripción clara de tus cambios
   - Referencia cualquier issue relacionado (#numero-de-issue)

## 📝 Convenciones de código

### Estilo de código

1. **Indentación**
   - Usa 4 espacios para la indentación (no tabs)
   - Mantén consistencia con el estilo existente

2. **Nombres**
   - Funciones: `usar_snake_case` para nombres de funciones
   - Variables: `usar_tambien_snake_case` para nombres de variables
   - Constantes: `EN_MAYUSCULAS` para constantes

3. **Comentarios**
   - Documenta todas las funciones con un comentario que explique:
     - Qué hace la función
     - Los parámetros que recibe
     - El valor que devuelve
   - Añade comentarios para explicar lógica compleja

4. **Mensajes de usuario**
   - Utiliza la función `print_message()` para todos los mensajes al usuario
   - Usa los colores adecuados: `$GREEN` para éxito, `$YELLOW` para advertencias, `$RED` para errores, `$BLUE` para información

### Principios de diseño

1. **SOLID**
   - Responsabilidad Única: Cada script/módulo debe tener una sola responsabilidad
   - Abierto/Cerrado: Los módulos deben ser extensibles sin modificar el código existente
   - Sustitución de Liskov: Los detectores de framework y motores de base de datos deben ser intercambiables
   - Segregación de Interfaces: Funciones agrupadas de manera coherente
   - Inversión de Dependencias: Módulos de alto nivel no dependen de detalles de implementación

2. **Modularidad**
   - Divide la funcionalidad en módulos autocontenidos
   - Evita dependencias circulares entre módulos

3. **Manejo de errores**
   - Utiliza `error_exit()` para errores fatales
   - Utiliza `warning_message()` para advertencias no fatales
   - Verifica siempre las condiciones de error

## 📂 Estructura del proyecto

```
apache-vhost-orchestrator/
├── bin/                         # Scripts ejecutables
│   ├── vhost-manager.sh         # Punto de entrada unificado
│   ├── setup-environment.sh     # Script de configuración
│   ├── clear-environments.sh    # Script de limpieza
│   └── functions.sh             # Funciones compartidas
├── modules/                     # Componentes modulares
│   ├── framework-detection/     # Detección de frameworks
│   │   ├── detect.sh            # Sistema central de detección
│   │   ├── laravel.sh           # Detector de Laravel
│   │   └── generic-php.sh       # Soporte para PHP genérico
│   ├── database/                # Sistema multi-motor de bases de datos
│   │   ├── detect.sh            # Detección de motores disponibles
│   │   ├── create-db.sh         # Creación de bases de datos
│   │   ├── clean-db.sh          # Limpieza de bases de datos
│   │   └── engines/             # Implementaciones específicas por motor
│   │       ├── mysql.sh         # Motor MySQL
│   │       ├── postgresql.sh    # Motor PostgreSQL
│   │       ├── sqlite.sh        # Motor SQLite
│   │       ├── sqlserver.sh     # Motor SQL Server
│   │       └── mongodb.sh       # Motor MongoDB
│   └── xdebug/                  # Configuración de Xdebug
│       └── configure.sh         # Configuración inteligente de Xdebug
└── templates/                   # Plantillas (para uso futuro)
```

- **Respeta esta estructura** al añadir nuevos archivos
- **Añade nuevos módulos** en directorios independientes dentro de `modules/`
- **Funciones reutilizables** deberían ir en `functions.sh` o en un módulo específico

## 🔧 Ampliando la funcionalidad

### Añadir soporte para un nuevo framework

1. **Crea un nuevo detector de framework**
   - Añade un archivo `tu-framework.sh` en `modules/framework-detection/`
   - Implementa una función `detect_tu_framework()` que devuelva 0 (verdadero) o 1 (falso)
   - Implementa funciones específicas para configurar ese framework

2. **Actualiza el sistema de detección principal**
   - Modifica `modules/framework-detection/detect.sh` para importar tu nuevo detector
   - Añade tu framework a la cadena de detección en `detect_framework()`
   - Añade la configuración adecuada en `FRAMEWORK_SETTINGS`

Ejemplo de detector para Symfony:
```bash
#!/bin/bash

# Detecta si un directorio contiene un proyecto Symfony
detect_symfony() {
    local project_path=$1
    
    # Comprueba archivos/directorios clave de Symfony
    if [ -f "$project_path/bin/console" ] && \
       [ -d "$project_path/src" ] && \
       [ -d "$project_path/public" ] && \
       [ -f "$project_path/composer.json" ]; then
        
        # Comprobación adicional: verifica que composer.json contiene symfony
        if grep -q "symfony/symfony" "$project_path/composer.json" 2>/dev/null || \
           grep -q "symfony/framework-bundle" "$project_path/composer.json" 2>/dev/null; then
            return 0  # Verdadero (Symfony detectado)
        fi
    fi
    
    return 1  # Falso (No es Symfony)
}

# Configura ajustes específicos para Symfony
configure_symfony() {
    local project_path=$1
    local domain=$2
    
    print_message "🚀 Configurando proyecto Symfony..." "$BLUE"
    
    # Implementa la configuración específica de Symfony aquí
    
    print_message "✅ Configuración de Symfony completada." "$GREEN"
}
```

### Añadir soporte para un nuevo motor de base de datos

1. **Crea un nuevo motor de base de datos**
   - Añade un archivo `tu-motor.sh` en `modules/database/engines/`
   - Implementa funciones `create_tu_motor_db()` y `clean_tu_motor_db()`
   - Sigue el patrón de los motores existentes

2. **Actualiza el sistema de detección**
   - Modifica `modules/database/detect.sh` para detectar el nuevo motor
   - Añade la detección en la función `detect_database_engines()`

3. **Actualiza el sistema de creación y limpieza**
   - Añade el nuevo motor en `create-db.sh` y `clean-db.sh`
   - Mantén la consistencia con los motores existentes

Ejemplo de implementación para un motor Oracle:
```bash
#!/bin/bash

# Función específica para crear base de datos Oracle
create_oracle_db() {
    local project_name=$1
    
    # Normalizar nombre del proyecto para Oracle
    local db_name=$(echo "${project_name}" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
    local db_user="${project_name}_user"
    local db_pass="password123"
    
    print_message "🗄️ Creando base de datos Oracle: $db_name" "$BLUE"
    
    # Verificar que Oracle está instalado y disponible
    if ! command -v sqlplus &> /dev/null; then
        print_message "   ❌ Cliente Oracle SQL*Plus no encontrado" "$RED"
        return 1
    fi
    
    # Solicitar credenciales de administrador
    read -p "Introduce el usuario administrador de Oracle (system): " oracle_admin
    oracle_admin=${oracle_admin:-"system"}
    
    read -sp "Introduce la contraseña del administrador: " oracle_admin_pass
    echo ""
    
    # Implementa la lógica para crear usuario y base de datos
    # ...
    
    # Devuelve la configuración necesaria
    echo "DB_CONNECTION=oracle"
    echo "DB_HOST=localhost"
    echo "DB_PORT=1521"
    echo "DB_SERVICE_NAME=$db_name"
    echo "DB_USERNAME=$db_user"
    echo "DB_PASSWORD=$db_pass"
    
    return 0
}

# Función para limpiar bases de datos Oracle
clean_oracle_db() {
    local project_name=$1
    
    # Implementa la lógica para limpiar usuario y tablespace
    # ...
    
    return 0
}
```

### Añadir nuevas funcionalidades generales

1. **Determina dónde debe ir tu funcionalidad**
   - Si es específica de un framework: en el módulo de ese framework
   - Si es específica de un motor de base de datos: en el módulo de ese motor
   - Si es una utilidad general: en `functions.sh`
   - Si es una nueva categoría: crea un nuevo módulo en `modules/`

2. **Sigue los principios SOLID**
   - Crea funciones con una sola responsabilidad
   - Diseña para extensibilidad

3. **Documenta completamente la nueva funcionalidad**
   - Añade comentarios explicativos
   - Actualiza el README.md si es necesario

## 👀 Proceso de revisión

1. **Revisión inicial**
   - Verificaremos que tu PR cumpla con las convenciones de código
   - Comprobaremos que siga los principios de diseño

2. **Pruebas**
   - Probaremos tu código en diferentes entornos
   - Verificaremos que no rompe ninguna funcionalidad existente

3. **Iteración**
   - Es posible que solicitemos cambios o mejoras
   - Trabajaremos contigo para pulir la contribución

4. **Merge**
   - Una vez aprobado, fusionaremos tu PR
   - ¡Y te daremos crédito como contribuyente!

## ❓ ¿Preguntas?

Si tienes preguntas sobre cómo contribuir, abre un issue con la etiqueta "pregunta" o "ayuda-deseada".

¡Gracias por contribuir a Apache VHOST Orchestrator! Tu ayuda es muy valiosa para mejorar esta herramienta.

---

# 🤝 Contributing to Apache VHOST Orchestrator

<p align="center">
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome">
  <img src="https://img.shields.io/badge/bash-5.1%2B-brightgreen" alt="Bash 5.1+">
  <img src="https://img.shields.io/badge/Apache-2.4%2B-red" alt="Apache 2.4+">
</p>

---

[🇪🇸 Español](#-contribuyendo-al-apache-vhost-orchestrator) | **🇬🇧 English**

Thank you for your interest in improving Apache VHOST Orchestrator! This document will guide you through the contribution process, from setting up your environment to submitting your Pull Request.

## 📋 Table of Contents
- [Getting Started](#-getting-started)
- [Contribution Process](#-contribution-process)
- [Code Conventions](#-code-conventions)
- [Project Structure](#-project-structure)
- [Expanding Functionality](#-expanding-functionality)
- [Review Process](#-review-process)

## 🚀 Getting Started

### Prerequisites
To work on this project, you'll need:
- Linux (Ubuntu/Debian recommended)
- Git
- Apache 2.4+
- PHP 7.4+ (preferably 8.x)
- At least one of these database engines (for testing):
  - MySQL/MariaDB
  - PostgreSQL
  - SQLite
  - SQL Server
  - MongoDB
- Bash 5.1+

### Environment Setup
1. **Fork the repository**
   - Click the "Fork" button at the top right of the GitHub page

2. **Clone your fork locally**
   ```bash
   git clone https://github.com/YOUR-USERNAME/apache-vhost-orchestrator.git
   cd apache-vhost-orchestrator
   ```

3. **Set up execution permissions**
   ```bash
   chmod +x bin/*.sh
   chmod +x modules/*/*.sh
   chmod +x modules/database/engines/*.sh
   ```

4. **Set up the upstream repository (optional but recommended)**
   ```bash
   git remote add upstream https://github.com/joseantoniopino/apache-vhost-orchestrator.git
   ```

## 🔄 Contribution Process

1. **Sync your fork** (if some time has passed since you created it)
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. **Create a branch for your contribution**
   ```bash
   git checkout -b descriptive-branch-name
   ```
   Use a descriptive name related to your contribution, for example:
   - `feature/symfony-support`
   - `feature/oracle-support`
   - `fix/xdebug-permissions`
   - `docs/improve-modules-documentation`

3. **Make your changes**
   - Implement the changes following the [code conventions](#-code-conventions)
   - Ensure your code follows SOLID principles

4. **Test your changes**
   - Run the script in your local environment to ensure it works correctly
   - Verify that it doesn't break any existing functionality

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Clear and concise description of your changes"
   ```
   - Use descriptive commit messages
   - Use imperative verbs (e.g., "Add support for...", not "Added support for...")

6. **Push to your fork**
   ```bash
   git push origin descriptive-branch-name
   ```

7. **Create a Pull Request**
   - Go to your fork's GitHub page
   - Click "Compare & pull request"
   - Provide a clear description of your changes
   - Reference any related issues (#issue-number)

## 📝 Code Conventions

### Code Style

1. **Indentation**
   - Use 4 spaces for indentation (not tabs)
   - Maintain consistency with existing style

2. **Naming**
   - Functions: `use_snake_case` for function names
   - Variables: `also_use_snake_case` for variable names
   - Constants: `USE_UPPERCASE` for constants

3. **Comments**
   - Document all functions with a comment explaining:
     - What the function does
     - The parameters it receives
     - The value it returns
   - Add comments to explain complex logic

4. **User Messages**
   - Use the `print_message()` function for all user messages
   - Use appropriate colors: `$GREEN` for success, `$YELLOW` for warnings, `$RED` for errors, `$BLUE` for information

### Design Principles

1. **SOLID**
   - Single Responsibility: Each script/module should have only one responsibility
   - Open/Closed: Modules should be extensible without modifying existing code
   - Liskov Substitution: Framework detectors and database engines should be interchangeable
   - Interface Segregation: Functions grouped coherently
   - Dependency Inversion: High-level modules don't depend on implementation details

2. **Modularity**
   - Divide functionality into self-contained modules
   - Avoid circular dependencies between modules

3. **Error Handling**
   - Use `error_exit()` for fatal errors
   - Use `warning_message()` for non-fatal warnings
   - Always check for error conditions

## 📂 Project Structure

```
apache-vhost-orchestrator/
├── bin/                         # Executable scripts
│   ├── vhost-manager.sh         # Unified entry point
│   ├── setup-environment.sh     # Setup script
│   ├── clear-environments.sh    # Cleanup script
│   └── functions.sh             # Shared functions
├── modules/                     # Modular components
│   ├── framework-detection/     # Framework detection
│   │   ├── detect.sh            # Core detection system
│   │   ├── laravel.sh           # Laravel detector
│   │   └── generic-php.sh       # Generic PHP support
│   ├── database/                # Multi-engine database system
│   │   ├── detect.sh            # Detection of available engines
│   │   ├── create-db.sh         # Database creation
│   │   ├── clean-db.sh          # Database cleanup
│   │   └── engines/             # Engine-specific implementations
│   │       ├── mysql.sh         # MySQL engine
│   │       ├── postgresql.sh    # PostgreSQL engine
│   │       ├── sqlite.sh        # SQLite engine
│   │       ├── sqlserver.sh     # SQL Server engine
│   │       └── mongodb.sh       # MongoDB engine
│   └── xdebug/                  # Xdebug configuration
│       └── configure.sh         # Intelligent Xdebug configuration
└── templates/                   # Templates (for future use)
```

- **Respect this structure** when adding new files
- **Add new modules** in separate directories within `modules/`
- **Reusable functions** should go in `functions.sh` or in a specific module

## 🔧 Expanding Functionality

### Adding Support for a New Framework

1. **Create a new framework detector**
   - Add a `your-framework.sh` file in `modules/framework-detection/`
   - Implement a `detect_your_framework()` function that returns 0 (true) or 1 (false)
   - Implement specific functions to configure that framework

2. **Update the main detection system**
   - Modify `modules/framework-detection/detect.sh` to import your new detector
   - Add your framework to the detection chain in `detect_framework()`
   - Add the appropriate configuration in `FRAMEWORK_SETTINGS`

Example of a detector for Symfony:
```bash
#!/bin/bash

# Detects if a directory contains a Symfony project
detect_symfony() {
    local project_path=$1
    
    # Check for key Symfony files/directories
    if [ -f "$project_path/bin/console" ] && \
       [ -d "$project_path/src" ] && \
       [ -d "$project_path/public" ] && \
       [ -f "$project_path/composer.json" ]; then
        
        # Additional check: verify composer.json contains symfony
        if grep -q "symfony/symfony" "$project_path/composer.json" 2>/dev/null || \
           grep -q "symfony/framework-bundle" "$project_path/composer.json" 2>/dev/null; then
            return 0  # True (Symfony detected)
        fi
    fi
    
    return 1  # False (Not Symfony)
}

# Configure Symfony-specific settings
configure_symfony() {
    local project_path=$1
    local domain=$2
    
    print_message "🚀 Configuring Symfony project..." "$BLUE"
    
    # Implement Symfony-specific configuration here
    
    print_message "✅ Symfony configuration completed." "$GREEN"
}
```

### Adding Support for a New Database Engine

1. **Create a new database engine implementation**
   - Add a `your-engine.sh` file in `modules/database/engines/`
   - Implement functions `create_your_engine_db()` and `clean_your_engine_db()`
   - Follow the pattern of existing engines

2. **Update the detection system**
   - Modify `modules/database/detect.sh` to detect the new engine
   - Add detection in the `detect_database_engines()` function

3. **Update the creation and cleanup systems**
   - Add the new engine in `create-db.sh` and `clean-db.sh`
   - Maintain consistency with existing engines

Example implementation for an Oracle engine:
```bash
#!/bin/bash

# Function to create an Oracle database
create_oracle_db() {
    local project_name=$1
    
    # Normalize project name for Oracle
    local db_name=$(echo "${project_name}" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
    local db_user="${project_name}_user"
    local db_pass="password123"
    
    print_message "🗄️ Creating Oracle database: $db_name" "$BLUE"
    
    # Verify that Oracle is installed and available
    if ! command -v sqlplus &> /dev/null; then
        print_message "   ❌ Oracle SQL*Plus client not found" "$RED"
        return 1
    fi
    
    # Request admin credentials
    read -p "Enter Oracle admin username (system): " oracle_admin
    oracle_admin=${oracle_admin:-"system"}
    
    read -sp "Enter admin password: " oracle_admin_pass
    echo ""
    
    # Implement logic to create user and database
    # ...
    
    # Return necessary configuration
    echo "DB_CONNECTION=oracle"
    echo "DB_HOST=localhost"
    echo "DB_PORT=1521"
    echo "DB_SERVICE_NAME=$db_name"
    echo "DB_USERNAME=$db_user"
    echo "DB_PASSWORD=$db_pass"
    
    return 0
}

# Function to clean Oracle databases
clean_oracle_db() {
    local project_name=$1
    
    # Implement logic to clean user and tablespace
    # ...
    
    return 0
}
```

### Adding New General Functionality

1. **Determine where your functionality should go**
   - If framework-specific: in that framework's module
   - If database engine-specific: in that engine's module
   - If a general utility: in `functions.sh`
   - If a new category: create a new module in `modules/`

2. **Follow SOLID principles**
   - Create functions with a single responsibility
   - Design for extensibility

3. **Fully document the new functionality**
   - Add explanatory comments
   - Update README.md if necessary

## 👀 Review Process

1. **Initial Review**
   - We'll verify that your PR meets the code conventions
   - We'll check that it follows the design principles

2. **Testing**
   - We'll test your code in different environments
   - We'll verify that it doesn't break any existing functionality

3. **Iteration**
   - We may request changes or improvements
   - We'll work with you to polish the contribution

4. **Merge**
   - Once approved, we'll merge your PR
   - And credit you as a contributor!

## ❓ Questions?

If you have questions about how to contribute, open an issue with the label "question" or "help-wanted".

Thank you for contributing to Apache VHOST Orchestrator! Your help is greatly valuable in improving this tool.
