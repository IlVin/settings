#!/bin/bash +x

# Проект
export PRJ_DOMAIN="wp.iv77msk.ru"
export PRJ_EMAIL="ilvin@mail.ru"
export PRJ_NAME=${PRJ_DOMAIN}
export PRJ_ROOT="/www/${PRJ_NAME}"
export PRJ_OWNER="www"
export PRJ_GROUP="www"
export CERT_DIR="${PRJ_ROOT}/cert"
export CONF_DIR="${PRJ_ROOT}/conf"
export CACHE_DIR="${PRJ_ROOT}/cache"
export PID_DIR="${PRJ_ROOT}/pid"
export HTDOCS_DIR="${PRJ_ROOT}/htdocs"
export WP_DIR="${HTDOCS_DIR}"
export LOG_DIR="${PRJ_ROOT}/logs"
export DB_DIR="${PRJ_ROOT}/mysql"
export SOFT_DIR="${PRJ_ROOT}/soft"

# Security
export DEFAULT_PASSWD="P@ssw0rd"

# Установки базы данных
export DB_DEV_HOST="localhost"
export DB_DEV_NAME="wp_${PRJ_NAME}_dev"
export DB_DEV_USER=${USER}
export DB_DEV__PASSWORD=${DEFAULT_PASSWD}
export DB_PROD_HOST="localhost"
export DB_PROD_NAME="wp_${PRJ_NAME}_prod"
export DB_PROD_USER=${USER}
export DB_PROD__PASSWORD=${DEFAULT_PASSWD}
