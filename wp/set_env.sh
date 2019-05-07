#!/bin/bash -x

# Проект
export PRJ_NAME='wp'
export PRJ_DOMAINS=("${PRJ_NAME}.iv77msk.ru" "www.${PRJ_NAME}.iv77msk.ru")
export PRJ_DOMAIN=${PRJ_DOMAINS[0]}
export PRJ_EMAIL="ilvin@mail.ru"
export PRJ_ROOT="/www/${PRJ_NAME}"
export PRJ_OWNER="www"
export PRJ_GROUP="www"
export CACHE_DIR="${PRJ_ROOT}/cache"
export HTDOCS_DIR="${PRJ_ROOT}/htdocs"
export WP_DIR="${HTDOCS_DIR}"
export DB_DIR="${PRJ_ROOT}/mysql"
export SOFT_DIR="${PRJ_ROOT}/soft"

export NET_PRD="${PRJ_NAME}_net_prd"
export NET_ADM="${PRJ_NAME}_net_adm"

export CONF_DIR="${PRJ_ROOT}/conf"
export CONF_NGINX="${CONF_DIR}/nginx.conf"
export CONF_UNIT_ADM="${CONF_DIR}/unit_adm.json"
export CONF_UNIT_PRD="${CONF_DIR}/unit_prd.json"

export IMG_DIR_BASE="${CONF_DIR}/img_base"
export IMG_DIR_NGINX="${CONF_DIR}/img_nginx"
export IMG_DIR_FPM="${CONF_DIR}/img_fpm"
export IMG_DIR_FPM_ADM="${CONF_DIR}/img_fpm_adm"
export IMG_DIR_FPM_PRD="${CONF_DIR}/img_fpm_prd"

export IMG_NAME_BASE="${PRJ_NAME}_base:v001"
export IMG_NAME_NGINX="${PRJ_NAME}_nginx:v001"
export IMG_NAME_FPM="${PRJ_NAME}_fpm:v001"
export IMG_NAME_FPM_ADM="${PRJ_NAME}_fpm_adm:v001"
export IMG_NAME_FPM_PRD="${PRJ_NAME}_fpm_prd:v001"

export RUN_DIR="${PRJ_ROOT}/run"
export RUN_DIR_NGINX="${RUN_DIR}/nginx"
export RUN_DIR_UNIT_ADM="${RUN_DIR}/unit_adm"
export RUN_DIR_UNIT_PRD="${RUN_DIR}/unit_prd"
export RUN_DIR_FPM_ADM="${RUN_DIR}/fpm_adm"
export RUN_DIR_FPM_PRD="${RUN_DIR}/fpm_prd"

export LOG_DIR="${PRJ_ROOT}/logs"
export LOG_DIR_NGINX="${LOG_DIR}/nginx"
export LOG_DIR_UNIT_ADM="${LOG_DIR}/unit_adm"
export LOG_DIR_UNIT_PRD="${LOG_DIR}/unit_prd"
export LOG_DIR_FPM_ADM="${LOG_DIR}/fpm_adm"
export LOG_DIR_FPM_PRD="${LOG_DIR}/fpm_prd"

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
export PORT_UNIT_ADM="8080"
export PORT_UNIT_PRD="8081"
export PORT_FPM_ADM="8082"
export PORT_FPM_PRD="8083"

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
export DB_NAME_PRD="wp_${PRJ_NAME}_prd"
export DB_USER_PRD=${USER}
export DB_PASSWORD_PRD=${DEFAULT_PASSWD}

export DB_HOST_ADM="localhost"
export DB_PORT_ADM="localhost"
export DB_NAME_ADM="wp_${PRJ_NAME}_adm"
export DB_USER_ADM=${USER}
export DB_PASSWORD_ADM=${DEFAULT_PASSWD}

export USER_ADM=${PRJ_OWNER}
export GROUP_ADM=${PRJ_GROUP}
export USER_PRD='www-prd'
export GROUP_PRD='www-prd'

export PHPVER='7.2'
export TIMEZONE='Europe/Moscow'
export PHP_MEMORY_LIMIT='1024M'
export MAX_UPLOAD='128M'
export PHP_MAX_FILE_UPLOAD='128'
export PHP_MAX_POST='128M'

function net_adm_ids() {
    sudo docker network ls -f NAME=${NET_ADM} -q
}

function net_prd_ids() {
    sudo docker network ls -f NAME=${NET_PRD} -q
}

function net_bridge_ids() {
    sudo docker network ls -f NAME=bridge -q
}

function fpm_adm_ids() {
    sudo docker container ls -a -f NAME=${HOSTNAME_FPM_PRD} -q
}

function fpm_prd_ids() {
    sudo docker container ls -a -f NAME=${HOSTNAME_FPM_ADM} -q
}

function nginx_ids() {
    sudo docker container ls -a -f NAME=${HOSTNAME_NGINX} -q
}

function LSB() {
    lsb_release -s -c
}

function RELEASE() {
    lsb_release -r | sed -r 's/Release:\s+//'
}

function escaped_htdocs_dir() {
    echo ${HTDOCS_DIR} | sed -r 's/\//\\\//g'
}
