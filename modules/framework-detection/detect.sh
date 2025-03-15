#!/bin/bash

# Framework detection system following Open/Closed principle
# Main detection module that integrates all detectors

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Import detector modules - each detector is a separate module
source "$SCRIPT_DIR/laravel.sh"
# Future framework detectors would be added here:
# source "$(dirname "$0")/symfony.sh"
# source "$(dirname "$0")/codeigniter.sh"
source "$SCRIPT_DIR/generic-php.sh"

# Framework settings - each framework has specific settings
declare -A FRAMEWORK_SETTINGS
# Default public directory paths
FRAMEWORK_SETTINGS["laravel,public_dir"]="/public"
# Future framework public directories would be added here:
# FRAMEWORK_SETTINGS["symfony,public_dir"]="/public"
# FRAMEWORK_SETTINGS["codeigniter,public_dir"]="/public"
FRAMEWORK_SETTINGS["generic_php,public_dir"]="/public" # Default for generic PHP

# Main detection function - runs all detectors in sequence
detect_framework() {
    local project_path=$1
    local result="generic_php" # Default if no framework is detected

    # Check if directory exists
    if [ ! -d "$project_path" ]; then
        echo "$result"
        return
    fi

    # Try each detector in priority order
    if detect_laravel "$project_path"; then
        result="laravel"
    # Future framework detectors would be added here:
    # elif detect_symfony "$project_path"; then
    #     result="symfony"
    # elif detect_codeigniter "$project_path"; then
    #     result="codeigniter"
    elif detect_generic_php "$project_path"; then
        result="generic_php"
    fi

    echo "$result"
}

# Get public directory for detected framework
get_framework_public_dir() {
    local framework=$1
    local project_path=$2

    # Look up the public directory in the settings map
    local public_dir_suffix="${FRAMEWORK_SETTINGS["${framework},public_dir"]}"

    # Default to root if not found
    if [ -z "$public_dir_suffix" ]; then
        public_dir_suffix=""
    fi

    echo "${project_path}${public_dir_suffix}"
}

# Check if project directory is empty
is_project_empty() {
    local project_path=$1
    if [ -z "$(ls -A "$project_path" 2>/dev/null)" ]; then
        return 0 # True - directory is empty
    else
        return 1 # False - directory contains files
    fi
}