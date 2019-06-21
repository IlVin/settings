#!/bin/bash

set +x

alias sudo='sudo -S'

export SET_ENV='INCLUDED'

export UMASK='0002'

umask ${UMASK}

export SERVICE_USER='iv77msk_ru'
export SERVICE_HOST='ca.iv77msk.ru'
#export SERVICE_HOME=$(grep ${SERVICE_USER} /etc/passwd | cut -d ':' -f 6)

# Проект
export PRJ_NAME='wp'
export PRJ_DOMAINS=("${PRJ_NAME}.iv77msk.ru" "www.${PRJ_NAME}.iv77msk.ru")
export PRJ_DOMAIN=${PRJ_DOMAINS[0]}
export PRJ_EMAIL="ilvin@mail.ru"

export PRJ_ROOT="/${PRJ_NAME}"

export CERT_DIR="${PRJ_ROOT}/cert"
export CERT_CA_CERT_URL='https://ca.iv77msk.ru/iv77msk.ru_CA.crt'
export CERT_CA_CRT="${CERT_DIR}/iv77msk.ru_CA.crt"

export SITE_ROOT="${PRJ_ROOT}/site"
export HTDOCS_DIR="${SITE_ROOT}/htdocs"
export LOG_DIR="${SITE_ROOT}/logs"

export WP_DIR="${HTDOCS_DIR}"           # Папка, в которую WP сетапить (совпадает с ${HTDOCS_DIR})
export DB_DIR="${PRJ_ROOT}/mysql"
export SOFT_DIR="${PRJ_ROOT}/soft"      # Папка, в которую скачивается софт, например WP

export CACHE_DIR="${PRJ_ROOT}/cache"    # Кэш nginx
export RUN_DIR="${PRJ_ROOT}/run"        # Папка для UNIX сокетов
export CONF_DIR="${PRJ_ROOT}/conf"      # Папка для конфигов сайта

export CONF_NGINX="${CONF_DIR}/${PRJ_NAME}_nginx.conf"

export ROOT_FPM_ADM="${PRJ_ROOT}"
export ROOT_FPM_PRD="${PRJ_ROOT}/root_prd"

export SOCK_FPM_ADM="${RUN_DIR}/${PRJ_NAME}-adm.sock"
export SOCK_FPM_PRD="${RUN_DIR}/${PRJ_NAME}-prd.sock"

export ACCESS_LOG_NGINX="${LOG_DIR}/access-${PRJ_NAME}-nginx_log"
export ACCESS_LOG_FPM_ADM="${LOG_DIR}/access-${PRJ_NAME}-adm_log"
export ACCESS_LOG_FPM_PRD="${LOG_DIR}/access-${PRJ_NAME}-prd_log"

export ERROR_LOG_NGINX="${LOG_DIR}/error-${PRJ_NAME}-nginx_log"
export ERROR_LOG_FPM_ADM="${LOG_DIR}/error-${PRJ_NAME}-adm_log"
export ERROR_LOG_FPM_PRD="${LOG_DIR}/error-${PRJ_NAME}-prd_log"

export STATUS_PATH_NGINX="/${PRJ_NAME}-status_nginx"
export STATUS_PATH_FPM_ADM="/${PRJ_NAME}-status_adm"
export STATUS_PATH_FPM_PRD="/${PRJ_NAME}-status_prd"

export PING_PATH_NGINX="/${PRJ_NAME}-ping_nginx"
export PING_PATH_FPM_ADM="/${PRJ_NAME}-ping_adm"
export PING_PATH_FPM_PRD="/${PRJ_NAME}-ping_prd"

export PING_RESPONSE_NGINX="${PRJ_NAME}-pong_nginx"
export PING_RESPONSE_FPM_ADM="${PRJ_NAME}-pong_adm"
export PING_RESPONSE_FPM_PRD="${PRJ_NAME}-pong_prd"

export PORT_NGINX="80"

# Security
export DEFAULT_PASSWD="P@ssw0rd"

# Установки базы данных
export DB_NAME_WP="${PRJ_NAME}_wordpress"

export DB_HOST_PRD="localhost"
export DB_PORT_PRD="3306"
export DB_USER_PRD="${PRJ_NAME}-prd"
export DB_PASSWORD_PRD="${DEFAULT_PASSWD}-prd"

export DB_HOST_ADM="localhost"
export DB_PORT_ADM="3306"
export DB_USER_ADM="${PRJ_NAME}-adm"
export DB_PASSWORD_ADM="${DEFAULT_PASSWD}-adm"

# Установки пользователей
# Политика безопасности:
# 1) Каждый пользователь пишет файлы от своего имени.
# 2) Все пользователи принадлежат одной группе.
# 3) Пользователи из одной группы распоряжаются файлами как своими, т.е. UMASK = 0002
# 4) Публичный FPM не принадлежит общей группе, т.е. имеет режим READ_ONLY на файлы
# 5) Публичному FPM файлы сайта монтируются в READ_ONLY режиме
# 6) Публичный FPM делает chroot
# 7) Публичному FPM выдан доступ к БД в SELECT_ONLY режиме

export PRJ_OWNER="${PRJ_NAME}-www"
export PRJ_GROUP="${PRJ_NAME}-www"

export USER_NGINX="${PRJ_NAME}-nginx"
export GROUP_NGINX="${USER_NGINX}"

export USER_FPM_ADM="${PRJ_NAME}-adm"
export GROUP_FPM_ADM=${PRJ_GROUP}

export USER_FPM_PRD="${PRJ_NAME}-prd"
export GROUP_FPM_PRD=${USER_FPM_PRD}

export PHPVER='7.2'
export TIMEZONE='Europe/Moscow'
export PHP_MEMORY_LIMIT='1024M'
export MAX_UPLOAD='128M'
export PHP_MAX_FILE_UPLOAD='128'
export PHP_MAX_POST='128M'

function join_by() {
    local d=$1
    shift
    echo -n "$1"
    shift
    printf "%s" "${@/#/$d}"
}

function get_local_ip() {
    local ETH=$( ((ifconfig -s | awk '$11 ~ /^[^L]*R[^L]*$/ { print $1 }') && (ifconfig -s | awk '$11 ~ /R/ { print $1 }')) | head -n 1 )
    ((ifconfig ${ETH} | grep -P '\binet\b' | awk '{ print $2 }') && (ifconfig lo | grep -P '\binet\b' | awk '{ print $2 }')) | head -n 1
}

function LSB() {
    lsb_release -s -c
}

function RELEASE() {
    lsb_release -r | sed -r 's/Release:\s+//'
}

function start_nginx() {
    sudo service nginx start
    sudo systemctl status nginx.service
}

function stop_nginx() {
    sudo service nginx stop
}

function start_fpm() {
    sudo service php7.2-fpm start
    sudo systemctl status php7.2-fpm.service
}

function stop_fpm() {
    sudo service php7.2-fpm stop
}

function user_knownhost() {
    local user=$1
    local host=$2
    local user_home=$(grep ${user} /etc/passwd | cut -d ':' -f 6)
    [ -f ${user_home}/.ssh/known_hosts ] && sudo ssh-keygen -R ${host} -f ${user_home}/.ssh/known_hosts
    ssh-keyscan ${host} 2>/dev/null | sudo tee -a ${user_home}/.ssh/known_hosts > /dev/null
    sudo chown ${user}:${user} ${user_home}/.ssh/known_hosts
    sudo chmod a-rwx,u+rw ${user_home}/.ssh/known_hosts
}

set -x
