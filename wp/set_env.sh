#!/bin/bash -x

# Проект
export PRJ_DOMAINS=("wp.iv77msk.ru" "www.wp.iv77msk.ru")
export PRJ_DOMAIN=${PRJ_DOMAINS[0]}
export PRJ_EMAIL="ilvin@mail.ru"
export PRJ_NAME=${PRJ_DOMAIN}
export PRJ_INT_NET="${PRJ_NAME}_int"
export PRJ_ROOT="/www/${PRJ_NAME}"
export PRJ_OWNER="www"
export PRJ_GROUP="www"
export CONF_DIR="${PRJ_ROOT}/conf"
export CACHE_DIR="${PRJ_ROOT}/cache"
export HTDOCS_DIR="${PRJ_ROOT}/htdocs"
export WP_DIR="${HTDOCS_DIR}"
export DB_DIR="${PRJ_ROOT}/mysql"
export SOFT_DIR="${PRJ_ROOT}/soft"

export RUN_DIR="${PRJ_ROOT}/run"
export RUN_DIR_NGINX="${RUN_DIR}/nginx"
export RUN_DIR_UNIT_ADM="${RUN_DIR}/unit_adm"
export RUN_DIR_UNIT_PRD="${RUN_DIR}/unit_prd"

export LOG_DIR="${PRJ_ROOT}/logs"
export LOG_DIR_NGINX="${LOG_DIR}/nginx"
export LOG_DIR_UNIT_ADM="${LOG_DIR}/unit_adm"
export LOG_DIR_UNIT_PRD="${LOG_DIR}/unit_prd"

export STATE_DIR="${PRJ_ROOT}/state"
export STATE_DIR_UNIT_ADM="${STATE_DIR}/unit_adm"
export STATE_DIR_UNIT_PRD="${STATE_DIR}/unit_prd"

export CERT_DIR="${PRJ_ROOT}/cert"
export CERT_DIR_NGINX="${CERT_DIR}/nginx"
export CERT_DIR_UNIT_ADM="${STATE_DIR_UNIT_ADM}/certs"
export CERT_DIR_UNIT_PRD="${STATE_DIR_UNIT_PRD}/certs"

xport LOG_DIR_UNIT_PRD="${LOG_DIR}/unit_prd"

# Security
export DEFAULT_PASSWD="P@ssw0rd"

# Установки базы данных
export DB_DEV_HOST="localhost"
export DB_DEV_NAME="wp_${PRJ_NAME}_dev"
export DB_DEV_USER=${USER}
export DB_DEV_PASSWORD=${DEFAULT_PASSWD}
export DB_PROD_HOST="localhost"
export DB_PROD_NAME="wp_${PRJ_NAME}_prod"
export DB_PROD_USER=${USER}
export DB_PROD_PASSWORD=${DEFAULT_PASSWD}
export DB_PROD_RO_USER=${USER}
export DB_PROD_RO_PASSWORD=${DEFAULT_PASSWD}
