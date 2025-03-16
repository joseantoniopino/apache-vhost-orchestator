# 🚀 Apache VHOST Orchestrator

<p align="center">
  <img src="https://img.shields.io/badge/bash-5.1%2B-brightgreen" alt="Bash 5.1+">
  <img src="https://img.shields.io/badge/Apache-2.4%2B-red" alt="Apache 2.4+">
  <img src="https://img.shields.io/badge/PHP-7.4%2B-blue" alt="PHP 7.4+">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License MIT">
</p>

---

**🇪🇸 Español** | [🇬🇧 English](#-apache-vhost-orchestrator-1)

Sistema modular para la orquestación y gestión automática de entornos de desarrollo web en servidores Apache. Optimizado para proyectos PHP y Laravel con configuración inteligente según el tipo de framework detectado.

## ✨ Características principales

- 🔍 **Detección inteligente de frameworks**: Identifica automáticamente si el proyecto usa Laravel o PHP nativo
- 🌐 **Configuración de dominio local**: Configura automáticamente entradas en `/etc/hosts` y hosts virtuales de Apache
- 🔒 **Gestión de permisos**: Establece los permisos adecuados según el tipo de proyecto
- 🐞 **Configuración de Xdebug**: Instala y configura Xdebug de forma inteligente sin sobrescribir configuraciones personalizadas
- 🗄️ **Creación de bases de datos**: Configura automáticamente bases de datos MySQL y usuarios con privilegios
- 📋 **Generación de estructura de proyectos**: Para proyectos PHP nativos, ofrece crear una estructura recomendada de directorios
- 🧹 **Limpieza de entornos**: Elimina fácilmente todos los recursos configurados cuando ya no se necesitan

## 📋 Requisitos previos

- Sistema operativo Linux (probado en Ubuntu/Debian)
- Apache 2.4 o superior
- PHP 7.4 o superior (recomendado PHP 8.x)
- MySQL/MariaDB
- Privilegios de administrador (sudo)

## 🔧 Instalación

1. Clona el repositorio:
```bash
git clone https://github.com/tu-usuario/apache-vhost-orchestrator.git
cd apache-vhost-orchestrator
```

2. Otorga permisos de ejecución a los scripts:
```bash
chmod +x bin/*.sh
```

3. (Opcional) Configura un alias para facilitar el acceso:
```bash
echo 'alias vhost-setup="sudo /ruta/a/apache-vhost-orchestrator/bin/setup-environment.sh"' >> ~/.bashrc
echo 'alias vhost-clear="sudo /ruta/a/apache-vhost-orchestrator/bin/clear-environments.sh"' >> ~/.bashrc
source ~/.bashrc
```

## 🚀 Uso

### Configurar un nuevo entorno

```bash
sudo ./bin/setup-environment.sh
```

El script te guiará a través de un proceso interactivo para:
1. Introducir el nombre del proyecto
2. Especificar la ruta del proyecto
3. Definir un dominio local (por defecto nombreproyecto.test)
4. El script detectará automáticamente si es un proyecto Laravel o PHP nativo
5. Configurará hosts virtuales, entradas DNS, permisos, Xdebug, etc.
6. Opcionalmente, creará una base de datos MySQL y un usuario

### Limpiar un entorno

```bash
sudo ./bin/clear-environments.sh
```

El script solicitará los dominios a limpiar y eliminará:
- Hosts virtuales de Apache
- Entradas en `/etc/hosts`
- Directorios de proyectos (opcional)
- Bases de datos y usuarios de MySQL (opcional)

## 📂 Estructura del proyecto

```
apache-vhost-orchestrator/
├── bin/                         # Scripts ejecutables
│   ├── setup-environment.sh     # Script principal
│   ├── clear-environments.sh    # Script de limpieza
│   └── functions.sh             # Funciones compartidas
├── modules/                     # Componentes modulares
│   ├── framework-detection/     # Detección de frameworks
│   │   ├── detect.sh            # Sistema central de detección
│   │   ├── laravel.sh           # Detector de Laravel
│   │   └── generic-php.sh       # Soporte para PHP genérico
│   └── xdebug/                  # Configuración de Xdebug
│       └── configure.sh         # Configuración inteligente de Xdebug
└── templates/                   # Plantillas (para uso futuro)
```

## 🔍 Diseño modular (SOLID)

El sistema sigue los principios SOLID:

- **S (Responsabilidad Única)**: Cada módulo tiene una única responsabilidad
- **O (Abierto/Cerrado)**: El sistema de detección de frameworks es extensible sin modificar el código existente
- **L (Sustitución de Liskov)**: Los diferentes detectores de framework son intercambiables
- **I (Segregación de Interfaces)**: Las funciones están agrupadas de manera coherente
- **D (Inversión de Dependencias)**: Los módulos de alto nivel no dependen de los detalles de implementación

## ⚙️ Ejemplos

### Configuración de un proyecto Laravel existente

```bash
sudo ./bin/setup-environment.sh
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

# El script configurará automáticamente todo para un proyecto Laravel
```

### Configuración de un proyecto PHP nativo

```bash
sudo ./bin/setup-environment.sh
```

```
# Para un directorio vacío, ofrecerá crear una estructura recomendada
El directorio del proyecto está vacío.
¿Quieres crear una estructura recomendada para un proyecto PHP? (s/n): s

# Para un directorio con contenido, permitirá seleccionar el directorio público
El directorio del proyecto ya contiene archivos.
Selecciona el directorio que debe ser accesible públicamente:
1) /home/usuario/www/proyecto (directorio raíz)
2) /home/usuario/www/proyecto/public
3) /home/usuario/www/proyecto/htdocs
...
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

# 🚀 Apache VHOST Orchestrator

<p align="center">
  <img src="https://img.shields.io/badge/bash-5.1%2B-brightgreen" alt="Bash 5.1+">
  <img src="https://img.shields.io/badge/Apache-2.4%2B-red" alt="Apache 2.4+">
  <img src="https://img.shields.io/badge/PHP-7.4%2B-blue" alt="PHP 7.4+">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License MIT">
</p>

---

[🇪🇸 Español](#-apache-vhost-orchestrator) | **🇬🇧 English**

Modular system for automatic orchestration and management of web development environments on Apache servers. Optimized for PHP and Laravel projects with intelligent configuration based on detected framework type.

## ✨ Key Features

- 🔍 **Intelligent Framework Detection**: Automatically identifies if the project uses Laravel or native PHP
- 🌐 **Local Domain Configuration**: Automatically configures entries in `/etc/hosts` and Apache virtual hosts
- 🔒 **Permission Management**: Sets appropriate permissions based on project type
- 🐞 **Xdebug Configuration**: Intelligently installs and configures Xdebug without overwriting custom configurations
- 🗄️ **Database Creation**: Automatically configures MySQL databases and users with privileges
- 📋 **Project Structure Generation**: For native PHP projects, offers to create a recommended directory structure
- 🧹 **Environment Cleanup**: Easily removes all configured resources when no longer needed

## 📋 Prerequisites

- Linux operating system (tested on Ubuntu/Debian)
- Apache 2.4 or higher
- PHP 7.4 or higher (PHP 8.x recommended)
- MySQL/MariaDB
- Administrator privileges (sudo)

## 🔧 Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/apache-vhost-orchestrator.git
cd apache-vhost-orchestrator
```

2. Grant execution permissions to scripts:
```bash
chmod +x bin/*.sh
```

3. (Optional) Configure an alias for easy access:
```bash
echo 'alias vhost-setup="sudo /path/to/apache-vhost-orchestrator/bin/setup-environment.sh"' >> ~/.bashrc
echo 'alias vhost-clear="sudo /path/to/apache-vhost-orchestrator/bin/clear-environments.sh"' >> ~/.bashrc
source ~/.bashrc
```

## 🚀 Usage

### Set up a new environment

```bash
sudo ./bin/setup-environment.sh
```

The script will guide you through an interactive process to:
1. Enter the project name
2. Specify the project path
3. Define a local domain (default is projectname.test)
4. The script will automatically detect if it's a Laravel or native PHP project
5. It will configure virtual hosts, DNS entries, permissions, Xdebug, etc.
6. Optionally, it will create a MySQL database and user

### Clean up an environment

```bash
sudo ./bin/clear-environments.sh
```

The script will ask for domains to clean up and will remove:
- Apache virtual hosts
- Entries in `/etc/hosts`
- Project directories (optional)
- MySQL databases and users (optional)

## 📂 Project Structure

```
apache-vhost-orchestrator/
├── bin/                         # Executable scripts
│   ├── setup-environment.sh     # Main script
│   ├── clear-environments.sh    # Cleanup script
│   └── functions.sh             # Shared functions
├── modules/                     # Modular components
│   ├── framework-detection/     # Framework detection
│   │   ├── detect.sh            # Core detection system
│   │   ├── laravel.sh           # Laravel detector
│   │   └── generic-php.sh       # Generic PHP support
│   └── xdebug/                  # Xdebug configuration
│       └── configure.sh         # Intelligent Xdebug configuration
└── templates/                   # Templates (for future use)
```

## 🔍 Modular Design (SOLID)

The system follows SOLID principles:

- **S (Single Responsibility)**: Each module has a single responsibility
- **O (Open/Closed)**: The framework detection system is extensible without modifying existing code
- **L (Liskov Substitution)**: Different framework detectors are interchangeable
- **I (Interface Segregation)**: Functions are grouped coherently
- **D (Dependency Inversion)**: High-level modules don't depend on implementation details

## ⚙️ Examples

### Setting up an existing Laravel project

```bash
sudo ./bin/setup-environment.sh
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

# The script will automatically configure everything for a Laravel project
```

### Setting up a native PHP project

```bash
sudo ./bin/setup-environment.sh
```

```
# For an empty directory, it will offer to create a recommended structure
The project directory is empty.
Do you want to create a recommended structure for a PHP project? (y/n): y

# For a directory with content, it will allow selecting the public directory
The project directory already contains files.
Select the directory that should be publicly accessible:
1) /home/user/www/project (root directory)
2) /home/user/www/project/public
3) /home/user/www/project/htdocs
...
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
