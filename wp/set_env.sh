#!/bin/bash -x

# Проект
export PRJ_NAME='wp'
export PRJ_DOMAINS=("${PRJ_NAME}.iv77msk.ru" "www.${PRJ_NAME}.iv77msk.ru")
export PRJ_DOMAIN=${PRJ_DOMAINS[0]}
export PRJ_EMAIL="ilvin@mail.ru"
export PRJ_PREFIX="/www"
export PRJ_ROOT="${PRJ_PREFIX}/${PRJ_NAME}"
export PRJ_OWNER="${PRJ_NAME}-www"
export PRJ_GROUP="${PRJ_NAME}-www"
export CACHE_DIR="${PRJ_ROOT}/cache"
export HTDOCS_DIR="${PRJ_ROOT}/htdocs"
export WP_DIR="${HTDOCS_DIR}"
export DB_DIR="${PRJ_ROOT}/mysql"
export SOFT_DIR="${PRJ_ROOT}/soft"

export NET_PRD="${PRJ_NAME}_net_prd"
export NET_ADM="${PRJ_NAME}_net_adm"

export CONF_DIR="${PRJ_ROOT}/conf"
export CONF_NGINX="${CONF_DIR}/nginx.conf"
export CONF_NGINX_ADM="${CONF_DIR}/nginx_adm.conf"
export CONF_NGINX_PRD="${CONF_DIR}/nginx_prd.conf"

#export ROOT_DIR_NGINX="${PRJ_ROOT}/root_nginx"
export ROOT_FPM_ADM="${PRJ_ROOT}/root_fpm_adm"
export ROOT_FPM_PRD="${PRJ_ROOT}/root_fpm_prd"

export RUN_DIR="${PRJ_ROOT}/run"
export RUN_DIR_NGINX="${RUN_DIR}/nginx"
export RUN_DIR_UNIT_ADM="${RUN_DIR}/unit_adm"
export RUN_DIR_UNIT_PRD="${RUN_DIR}/unit_prd"
export RUN_DIR_FPM_ADM="${RUN_DIR}/fpm_adm"
export RUN_DIR_FPM_PRD="${RUN_DIR}/fpm_prd"

export LOG_DIR="${PRJ_ROOT}/logs"
export ACCESS_LOG_NGINX="${LOG_DIR}/access-${PRJ_NAME}-nginx_log"
export ACCESS_LOG_FPM_ADM="${LOG_DIR}/access-${PRJ_NAME}-fpm-adm_log"
export ACCESS_LOG_FPM_PRD="${LOG_DIR}/access-${PRJ_NAME}-fpm-prd_log"
export ERROR_LOG_NGINX="${LOG_DIR}/error-${PRJ_NAME}-nginx_log"
export ERROR_LOG_FPM_ADM="${LOG_DIR}/error-${PRJ_NAME}-fpm-adm_log"
export WRROR_LOG_FPM_PRD="${LOG_DIR}/error-${PRJ_NAME}-fpm-prd_log"

export STATE_DIR="${PRJ_ROOT}/state"
export STATE_DIR_UNIT_ADM="${STATE_DIR}/unit_adm"
export STATE_DIR_UNIT_PRD="${STATE_DIR}/unit_prd"
export STATE_DIR_FPM_ADM="${STATE_DIR}/fpm_adm"
export STATE_DIR_FPM_PRD="${STATE_DIR}/fpm_prd"

export CERT_DIR="${PRJ_ROOT}/cert"
export CERT_DIR_NGINX="${CERT_DIR}/nginx"
export CERT_DIR_UNIT_ADM="${STATE_DIR_UNIT_ADM}/certs"
export CERT_DIR_UNIT_PRD="${STATE_DIR_UNIT_PRD}/certs"
export CERT_DIR_FPM_ADM="${STATE_DIR_FPM_ADM}/certs"
export CERT_DIR_FPM_PRD="${STATE_DIR_FPM_PRD}/certs"

export PORT_NGINX="80"
export SOCK_FPM_ADM="/run/php/${PRJ_NAME}-fpm-adm.sock"
export SOCK_FPM_PRD="/run/php/${PRJ_NAME}-fpm-prd.sock"

export HOSTNAME_NGINX="${PRJ_NAME}_nginx"
export HOSTNAME_UNIT_ADM="${PRJ_NAME}_unit_adm"
export HOSTNAME_UNIT_PRD="${PRJ_NAME}_unit_prd"
export HOSTNAME_FPM_ADM="${PRJ_NAME}_fpm_adm"
export HOSTNAME_FPM_PRD="${PRJ_NAME}_fpm_prd"


xport LOG_DIR_UNIT_PRD="${LOG_DIR}/unit_prd"

# Security
export DEFAULT_PASSWD="P@ssw0rd"

# Установки базы данных
export DB_HOST_PRD="localhost"
export DB_PORT_PRD="localhost"
export DB_NAME_PRD="${PRJ_NAME}_prd"
export DB_USER_PRD="${PRJ_NAME}-prd"
export DB_PASSWORD_PRD=${DEFAULT_PASSWD}

export DB_HOST_ADM="localhost"
export DB_PORT_ADM="localhost"
export DB_NAME_ADM="${PRJ_NAME}_adm"
export DB_USER_ADM="${PRJ_NAME}-adm"
export DB_PASSWORD_ADM=${DEFAULT_PASSWD}

export USER_NGINX='nginx'
export GROUP_NGINX=${PRJ_GROUP}

export USER_ADM="${PRJ_NAME}-adm"
export GROUP_ADM=${PRJ_GROUP}
export USER_PRD="${PRJ_NAME}-prd"
export GROUP_PRD=${PRJ_GROUP}

export USER_FPM_ADM="${PRJ_NAME}-fpm-adm"
export GROUP_FPM_ADM=${PRJ_GROUP}
export USER_FPM_PRD="${PRJ_NAME}-fpm-prd"
export GROUP_FPM_PRD=${PRJ_GROUP}

export PHPVER='7.2'
export TIMEZONE='Europe/Moscow'
export PHP_MEMORY_LIMIT='1024M'
export MAX_UPLOAD='128M'
export PHP_MAX_FILE_UPLOAD='128'
export PHP_MAX_POST='128M'

function net_adm_ids() {
    sudo docker network ls -f NAME=${NET_ADM} -q

function LSB() {
    lsb_release -s -c
}

function RELEASE() {
    lsb_release -r | sed -r 's/Release:\s+//'
}

function escaped_htdocs_dir() {
    echo ${HTDOCS_DIR} | sed -r 's/\//\\\//g'
}
