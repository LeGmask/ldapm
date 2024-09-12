#!/usr/bin/env bash

# A best practices Bash script template with many useful functions. This file
# sources in the bulk of the functions from the source.sh file which it expects
# to be in the same directory. Only those functions which are likely to need
# modification are present in this file. This is a great combination if you're
# writing several scripts! By pulling in the common functions you'll minimise
# code duplication, as well as ease any potential updates to shared functions.

# Enable xtrace if the DEBUG environment variable is set
if [[ ${DEBUG-} =~ ^1|yes|true$ ]]; then
    set -o xtrace # Trace the execution of the script (debug)
fi

# Only enable these shell behaviours if we're not being sourced
# Approach via: https://stackoverflow.com/a/28776166/8787985
if ! (return 0 2> /dev/null); then
    # A better class of script...
    set -o errexit  # Exit on most errors (see the manual)
    set -o nounset  # Disallow expansion of unset variables
    set -o pipefail # Use last non-zero exit code in a pipeline
fi

# Enable errtrace or the error trap handler will not work as expected
set -o errtrace # Ensure the error trap handler is inherited

# DESC: Usage help
# ARGS: None
# OUTS: None
# RETS: None
function script_usage() {
    cat << EOF

██╗     ██████╗  █████╗ ██████╗ ███╗   ███╗
██║     ██╔══██╗██╔══██╗██╔══██╗████╗ ████║
██║     ██║  ██║███████║██████╔╝██╔████╔██║
██║     ██║  ██║██╔══██║██╔═══╝ ██║╚██╔╝██║
███████╗██████╔╝██║  ██║██║     ██║ ╚═╝ ██║
╚══════╝╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝

A simple LDAP migration tool.
By default, ldapm will try to apply all migrations that have not been applied yet.
If you want to create a new migration, use the 'new' command.
Usage:
    new                         Create a new migration
    -h |--help                  Displays this help
    -v |--verbose               Displays verbose output
EOF
}

# DESC: Initialise the configuration file
# ARGS: None
# OUTS: .ldapm
# RETS: None
function setup_ldapm() {
    read -rp "Enter LDAP configuration file path: " ldap_conf
    read -rp "Enter LDAP database number: " ldap_db

    cat > .ldapm << EOF
# LDAP configuration file
LDAP_CONF=$ldap_conf
LDAP_DB=$ldap_db

# Migrations
EOF
}

# DESC: Check if migrations folder exists
# ARGS: None
# OUTS: migrations/
# RETS: None
function check_migrations_folder() {
    verbose_print "Checking migrations folder"
    if [[ ! -d "migrations" ]]; then
        verbose_print "Creating migrations folder"
        mkdir migrations
    fi
    verbose_print "Migrations folder exists"
}

# DESC: Check if .ldapm file exists
# ARGS: None
# OUTS: .ldapm
# RETS: None
function check_dot_ldapm() {
    verbose_print "Checking ldapm file"
    if [[ ! -f ".ldapm" ]]; then
        verbose_print "Creating ldapm file"
        setup_ldapm
    fi
    verbose_print "ldapm file exists"
}

# DESC: Initialise the script
# ARGS: None
# OUTS: .ldapm, migrations/
# RETS: None
function ldapm_init() {
    check_migrations_folder
    check_dot_ldapm
}

# DESC: Create a new migration
# ARGS: None
# OUTS: None
# RETS: None
function create_migration() {
    local migration_name
    read -rp "Enter migration name: " migration_name
    migration_name=$(date +"%Y%m%d%H%M%S")"_$migration_name.ldif"
    touch "migrations/$migration_name"
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
# RETS: None
function parse_params() {
    local param
    while [[ $# -gt 0 ]]; do
        param="$1"
        shift
        case $param in
            -h | --help)
                script_usage
                exit 0
                ;;
            -v | --verbose)
                verbose=true
                ;;
            new)
                create_migration
                exit 0
                ;;
            *)
                script_exit "Invalid parameter was provided: $param" 1
                ;;
        esac
    done
}

# DESC: Load LDAP configuration
# ARGS: None
# OUTS: LDAP_CONF, LDAP_DB
# RETS: None
function load_ldap_conf() {
    LDAP_CONF=$(grep "LDAP_CONF" .ldapm | cut -d'=' -f2)
    LDAP_DB=$(grep "LDAP_DB" .ldapm | cut -d'=' -f2)
}

# DESC: Migrate LDAP
# ARGS: None
# OUTS: None
# RETS: None
function migrate() {
    load_ldap_conf

    local migration
    for migration in migrations/*; do
        if ! grep -q "$migration" .ldapm; then
            pretty_print "Applying migration $migration" $fg_black
            slapadd -n "$LDAP_DB" -f "$LDAP_CONF" -l "$migration"
            echo "$migration" >> .ldapm
        fi
    done
    pretty_print "Successfully applied all migrations" $fg_green
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
# RETS: None
function main() {
    trap script_trap_err ERR
    trap script_trap_exit EXIT

    script_init "$@"
    ldapm_init
    colour_init

    parse_params "$@"

    migrate
}

# shellcheck source=source.sh
source "$(dirname "${BASH_SOURCE[0]}")/source.sh"

# Invoke main with args if not sourced
# Approach via: https://stackoverflow.com/a/28776166/8787985
if ! (return 0 2> /dev/null); then
    main "$@"
fi

# vim: syntax=sh cc=80 tw=79 ts=4 sw=4 sts=4 et sr
