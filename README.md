# 🚀 Automatic VHOST Orchestrator (AVO)

<p align="center">
  <img src="https://img.shields.io/badge/bash-5.1%2B-brightgreen" alt="Bash 5.1+">
  <img src="https://img.shields.io/badge/Web%20Servers-Compatible-red" alt="Web Servers">
  <img src="https://img.shields.io/badge/PHP-7.4%2B-blue" alt="PHP 7.4+">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License MIT">
</p>

---

**🇪🇸 Español** | [🇬🇧 English](#-automatic-vhost-orchestrator-avo-1)

Sistema modular para la orquestación y gestión automática de entornos de desarrollo web. Optimizado para proyectos PHP y Laravel con configuración inteligente según el tipo de framework detectado, compatible con diversos servidores web.

## ✨ Características principales

- 🔍 **Detección inteligente de frameworks**: Identifica automáticamente si el proyecto usa Laravel o PHP nativo
- 🌐 **Configuración de dominio local**: Configura automáticamente entradas en `/etc/hosts` y hosts virtuales en tu servidor web
- 🔒 **Gestión de permisos**: Establece los permisos adecuados según el tipo de proyecto
- 🐞 **Configuración de Xdebug**: Instala y configura Xdebug de forma inteligente sin sobrescribir configuraciones personalizadas
- 🗄️ **Sistema multi-motor de bases de datos**: Soporte para MySQL, PostgreSQL, SQLite, SQL Server y MongoDB
- 📋 **Generación de estructura de proyectos**: Para proyectos PHP nativos, ofrece crear una estructura recomendada de directorios
- 🧹 **Limpieza de entornos**: Elimina fácilmente todos los recursos configurados cuando ya no se necesitan
- 🔄 **Punto de entrada unificado**: Interfaz interactiva que simplifica tanto la creación como la limpieza de entornos
- 🔌 **Arquitectura extensible**: Diseñado para soportar múltiples servidores web mediante un sistema de módulos

## 📋 Requisitos previos

- Sistema operativo Linux (probado en Ubuntu/Debian)
- Servidor web instalado (actualmente compatible con Apache, con soporte para más servidores en desarrollo)
- PHP 7.4 o superior (recomendado PHP 8.x)
- Al menos uno de los siguientes motores de bases de datos:
  - MySQL/MariaDB
  - PostgreSQL
  - SQLite
  - SQL Server
  - MongoDB
- Privilegios de administrador (sudo)

## 🔧 Instalación

1. Clona el repositorio:
```bash
git clone https://github.com/tu-usuario/automatic-vhost-orchestrator.git
cd automatic-vhost-orchestrator
```

2. Otorga permisos de ejecución a los scripts:
```bash
chmod +x bin/*.sh
chmod +x modules/*/*.sh
chmod +x modules/database/engines/*.sh
```

3. (Opcional) Configura un alias para facilitar el acceso:
```bash
echo 'alias vhost-manager="sudo /ruta/a/automatic-vhost-orchestrator/bin/vhost-manager.sh"' >> ~/.bashrc
source ~/.bashrc
```

## 🚀 Uso

### Punto de entrada unificado (recomendado)

```bash
sudo ./bin/vhost-manager.sh
```

Este script te presentará un menú interactivo para seleccionar la acción que deseas realizar:
1. Configurar un nuevo entorno de desarrollo
2. Limpiar entornos existentes
3. Salir

### Acceso directo a funcionalidades específicas

También puedes acceder directamente a cada funcionalidad con parámetros:

```bash
# Ir directamente a la configuración de entorno
sudo ./bin/vhost-manager.sh --setup

# Ir directamente a la limpieza de entornos
sudo ./bin/vhost-manager.sh --clean

# Ver la ayuda del script
sudo ./bin/vhost-manager.sh --help
```

### Uso de scripts individuales (método alternativo)

Si prefieres utilizar los scripts individuales directamente:

#### Configurar un nuevo entorno
```bash
sudo ./bin/setup-environment.sh
```

#### Limpiar un entorno
```bash
sudo ./bin/clear-environments.sh
```

## 📂 Estructura del proyecto

```
automatic-vhost-orchestrator/
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
│   ├── webserver/               # Módulos para diferentes servidores web
│   │   ├── detect.sh            # Detección de servidores instalados
│   │   ├── apache.sh            # Configuración para Apache
│   │   └── [otros].sh           # Soporte para otros servidores web
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

## 🔍 Diseño modular (SOLID)

El sistema sigue los principios SOLID:

- **S (Responsabilidad Única)**: Cada módulo tiene una única responsabilidad
- **O (Abierto/Cerrado)**: Los sistemas de detección de frameworks, servidores web y bases de datos son extensibles sin modificar el código existente
- **L (Sustitución de Liskov)**: Los diferentes detectores y motores son intercambiables
- **I (Segregación de Interfaces)**: Las funciones están agrupadas de manera coherente
- **D (Inversión de Dependencias)**: Los módulos de alto nivel no dependen de los detalles de implementación

## 🔌 Extensibilidad para servidores web

AVO está diseñado con una arquitectura que permite añadir soporte para diferentes servidores web mediante módulos independientes:

- Cada servidor web tiene su propio módulo en `modules/webserver/`
- La detección automática del servidor instalado facilita la configuración
- Interfaces comunes para operaciones de configuración y limpieza
- Documentación específica sobre cómo implementar soporte para nuevos servidores

Ejemplos de servidores web que se pueden integrar en el sistema (actuales o futuros):
- Apache HTTP Server
- Nginx
- Caddy
- Lighttpd
- Cherokee
- LiteSpeed
- y cualquier otro servidor web que soporte hosts virtuales

## ⚙️ Ejemplos

### Uso del punto de entrada unificado

```bash
sudo ./bin/vhost-manager.sh
```

```
🚀 AUTOMATIC VHOST ORCHESTRATOR
➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
Sistema de gestión de entornos de desarrollo web
Optimizado para proyectos PHP y Laravel

📋 ¿Qué acción deseas realizar?
1. Configurar un nuevo entorno de desarrollo
2. Limpiar entornos existentes
3. Salir
Selecciona una opción [1-3]: 1

🔧 Iniciando configuración de nuevo entorno...
[El flujo continúa con la configuración de un nuevo entorno]
```

### Configuración de un proyecto Laravel con selección de base de datos

```bash
sudo ./bin/vhost-manager.sh --setup
```

```
Ingresa el nombre del proyecto: mi-blog
Ingresa la ruta completa del proyecto [/home/usuario/www/mi-blog]: /home/usuario/proyectos/mi-blog-laravel
Ingresa el dominio local para el proyecto [mi-blog.test]:

==== INFORMACIÓN DEL PROYECTO ====
Nombre del proyecto: mi-blog
Ruta del proyecto: /home/usuario/proyectos/mi-blog-laravel
Dominio local: mi-blog.test
¿Es correcta esta información? (s/n): s

🔍 Detectando tipo de framework...
   ✅ Framework detectado: laravel

🔍 Detectando servidores web disponibles...
   ✅ Apache detectado

🔍 Detectando motores de bases de datos disponibles...
   ✅ MySQL detectado
   ✅ PostgreSQL detectado
   ✅ SQLite detectado

¿Quieres crear una base de datos para este proyecto? (s/n): s

Selecciona el motor de base de datos a utilizar:
1) mysql
2) postgresql
3) sqlite
4) Ninguno
```

### Limpieza de un proyecto con múltiples bases de datos

```bash
sudo ./bin/vhost-manager.sh --clean
```

```
Introduce los nombres de dominio a limpiar: mi-blog

Se procesarán los siguientes dominios:
  - mi-blog.test
¿Es correcta esta lista? (s/n): s

⚠️ ADVERTENCIA: ¡Esto eliminará TODOS los rastros de los entornos seleccionados!
Esto incluye:
  - Hosts virtuales del servidor web
  - Entradas en /etc/hosts
  - Directorios de proyectos
  - Bases de datos (MySQL, PostgreSQL, SQLite, SQL Server, MongoDB)

¿Estás seguro de que quieres continuar? (s/n): s

# El script procederá a eliminar los recursos y preguntará qué motores 
# de bases de datos deseas limpiar para este proyecto
```

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

### ¿Qué significa la Licencia MIT?

La licencia MIT es una licencia de software permisiva que:
- ✅ Permite usar, copiar, modificar, fusionar, publicar, distribuir, sublicenciar y/o vender copias del software
- ✅ Solo requiere que se incluya el aviso de copyright y licencia en todas las copias
- ✅ No impone restricciones sobre el uso comercial o privado
- ✅ No ofrece garantías sobre el software
- ✅ No hace responsable al autor por daños derivados del uso del software

Es una de las licencias más permisivas y utilizadas en proyectos de código abierto, lo que facilita que otros desarrolladores puedan utilizar y contribuir al proyecto.

---

# 🚀 Automatic VHOST Orchestrator (AVO)

<p align="center">
  <img src="https://img.shields.io/badge/bash-5.1%2B-brightgreen" alt="Bash 5.1+">
  <img src="https://img.shields.io/badge/Web%20Servers-Compatible-red" alt="Web Servers">
  <img src="https://img.shields.io/badge/PHP-7.4%2B-blue" alt="PHP 7.4+">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License MIT">
</p>

---

[🇪🇸 Español](#-automatic-vhost-orchestrator-avo) | **🇬🇧 English**

Modular system for automatic orchestration and management of web development environments. Optimized for PHP and Laravel projects with intelligent configuration based on detected framework type, compatible with various web servers.

## ✨ Key Features

- 🔍 **Intelligent Framework Detection**: Automatically identifies if the project uses Laravel or native PHP
- 🌐 **Local Domain Configuration**: Automatically configures entries in `/etc/hosts` and virtual hosts in your web server
- 🔒 **Permission Management**: Sets appropriate permissions based on project type
- 🐞 **Xdebug Configuration**: Intelligently installs and configures Xdebug without overwriting custom configurations
- 🗄️ **Multi-engine Database System**: Support for MySQL, PostgreSQL, SQLite, SQL Server, and MongoDB
- 📋 **Project Structure Generation**: For native PHP projects, offers to create a recommended directory structure
- 🧹 **Environment Cleanup**: Easily removes all configured resources when no longer needed
- 🔄 **Unified Entry Point**: Interactive interface that simplifies both environment creation and cleanup
- 🔌 **Extensible Architecture**: Designed to support multiple web servers through a modular system

## 📋 Prerequisites

- Linux operating system (tested on Ubuntu/Debian)
- Web server installed (currently compatible with Apache, with support for more servers in development)
- PHP 7.4 or higher (PHP 8.x recommended)
- At least one of the following database engines:
  - MySQL/MariaDB
  - PostgreSQL
  - SQLite
  - SQL Server
  - MongoDB
- Administrator privileges (sudo)

## 🔧 Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/automatic-vhost-orchestrator.git
cd automatic-vhost-orchestrator
```

2. Grant execution permissions to scripts:
```bash
chmod +x bin/*.sh
chmod +x modules/*/*.sh
chmod +x modules/database/engines/*.sh
```

3. (Optional) Configure an alias for easy access:
```bash
echo 'alias vhost-manager="sudo /path/to/automatic-vhost-orchestrator/bin/vhost-manager.sh"' >> ~/.bashrc
source ~/.bashrc
```

## 🚀 Usage

### Unified Entry Point (recommended)

```bash
sudo ./bin/vhost-manager.sh
```

This script will present an interactive menu to select the action you want to perform:
1. Set up a new development environment
2. Clean up existing environments
3. Exit

### Direct Access to Specific Functionalities

You can also access each functionality directly with parameters:

```bash
# Go directly to environment setup
sudo ./bin/vhost-manager.sh --setup

# Go directly to environment cleanup
sudo ./bin/vhost-manager.sh --clean

# View script help
sudo ./bin/vhost-manager.sh --help
```

### Using Individual Scripts (alternative method)

If you prefer to use the individual scripts directly:

#### Set up a new environment
```bash
sudo ./bin/setup-environment.sh
```

#### Clean up an environment
```bash
sudo ./bin/clear-environments.sh
```

## 📂 Project Structure

```
automatic-vhost-orchestrator/
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
│   ├── webserver/               # Modules for different web servers
│   │   ├── detect.sh            # Detection of installed servers
│   │   ├── apache.sh            # Configuration for Apache
│   │   └── [others].sh          # Support for other web servers
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

## 🔍 Modular Design (SOLID)

The system follows SOLID principles:

- **S (Single Responsibility)**: Each module has a single responsibility
- **O (Open/Closed)**: The framework, web server, and database detection systems are extensible without modifying existing code
- **L (Liskov Substitution)**: Different detectors and engines are interchangeable
- **I (Interface Segregation)**: Functions are grouped coherently
- **D (Dependency Inversion)**: High-level modules don't depend on implementation details

## 🔌 Extensibility for Web Servers

AVO is designed with an architecture that allows adding support for different web servers through independent modules:

- Each web server has its own module in `modules/webserver/`
- Automatic detection of the installed server facilitates configuration
- Common interfaces for configuration and cleanup operations
- Specific documentation on how to implement support for new servers

Examples of web servers that can be integrated into the system (current or future):
- Apache HTTP Server
- Nginx
- Caddy
- Lighttpd
- Cherokee
- LiteSpeed
- and any other web server that supports virtual hosts

## ⚙️ Examples

### Using the Unified Entry Point

```bash
sudo ./bin/vhost-manager.sh
```

```
🚀 AUTOMATIC VHOST ORCHESTRATOR
➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
Web development environment management system
Optimized for PHP and Laravel projects

📋 What action would you like to perform?
1. Set up a new development environment
2. Clean up existing environments
3. Exit
Select an option [1-3]: 1

🔧 Starting new environment setup...
[The flow continues with setting up a new environment]
```

### Setting up a Laravel project with database selection

```bash
sudo ./bin/vhost-manager.sh --setup
```

```
Enter project name: my-blog
Enter full project path [/home/user/www/my-blog]: /home/user/projects/my-laravel-blog
Enter local domain for the project [my-blog.test]:

==== PROJECT INFORMATION ====
Project name: my-blog
Project path: /home/user/projects/my-laravel-blog
Local domain: my-blog.test
Is this information correct? (y/n): y

🔍 Detecting framework type...
   ✅ Framework detected: laravel

🔍 Detecting available web servers...
   ✅ Apache detected

🔍 Detecting available database engines...
   ✅ MySQL detected
   ✅ PostgreSQL detected
   ✅ SQLite detected

Do you want to create a database for this project? (y/n): y

Select the database engine to use:
1) mysql
2) postgresql
3) sqlite
4) None
```

### Cleaning up a project with multiple databases

```bash
sudo ./bin/vhost-manager.sh --clean
```

```
Enter the domain names to clean up: my-blog

The following domains will be processed:
  - my-blog.test
Is this list correct? (y/n): y

⚠️ WARNING: This will remove ALL traces of the selected environments!
This includes:
  - Web server virtual hosts
  - Entries in /etc/hosts
  - Project directories
  - Databases (MySQL, PostgreSQL, SQLite, SQL Server, MongoDB)

Are you sure you want to continue? (y/n): y

# The script will proceed to remove resources and ask which database
# engines you want to clean up for this project
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### What does the MIT License mean?

The MIT License is a permissive software license that:
- ✅ Allows using, copying, modifying, merging, publishing, distributing, sublicensing, and/or selling copies of the software
- ✅ Only requires that the copyright notice and license are included in all copies
- ✅ Does not impose restrictions on commercial or private use
- ✅ Does not provide warranties for the software
- ✅ Does not hold the author liable for damages arising from the use of the software

It is one of the most permissive and widely used licenses in open source projects, making it easy for other developers to use and contribute to the project.
