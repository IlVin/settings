#!/bin/bash

. ./set_env.sh

function run_container() {
    IMAGE=container:v001
    COMMAND=/bin/bash

    HOSTNAME=$(hostname)

    sudo docker run \
        --rm \
        -it \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        -v "$SSH_AUTH_SOCK:$SSH_AUTH_SOCK:rw" \
        -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK \
        -e SSH_USER=$USER \
        -h $HOSTNAME \
        ${IMAGE}
        ${COMMAND}
#        --dns 2a02:6b8:0:3400::1023 \
}

function run_nginx() {
    IMAGE="nginx:latest"
    HOSTNAME=$(hostname)
    CONTAINER_NAME="${PRJ_NAME}_nginx"

    sudo docker kill ${CONTAINER_NAME}

    sudo docker run \
        --name ${CONTAINER_NAME} \
        --rm \
        -it \
        --detach \
        --read-only \
        -v ${CONF_DIR}/nginx.conf:/etc/nginx/conf.d/${PRJ_DOMAIN}.conf:ro \
        -v ${CERT_DIR}:${CERT_DIR}:ro \
        -v ${HTDOCS_DIR}:${HTDOCS_DIR}:ro \
        -v ${LOG_DIR}/nginx/:/var/log/nginx/:rw \
        -v ${CACHE_DIR}/nginx/:/var/cache/nginx:rw \
        -v ${PID_DIR}/nginx.pid:/var/run/nginx.pid:rw \
        -h $HOSTNAME \
        --publish 80:80 \
        --publish 443:443 \
        ${IMAGE}
}

function run_nginx_unit_container() {
    IMAGE=nginx_unit_container:v001
    COMMAND=/bin/bash

    HOSTNAME=$(hostname)
install_mariadb

    sudo docker run \
        --rm \
        -it \
        -v ${HOME}/ilvin.git/wp/nginx_unit_container/www/prod/htdocs:/www/prod/:ro \
        -v ${HOME}/ilvin.git/wp/nginx_unit_container/www/dev/htdocs:/www/dev/:rw \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        -e USER=$USER \
        -h $HOSTNAME \
        ${IMAGE} \
        ${COMMAND}
}

function show_help() {
    echo "Unknown argument"
}

while (( $# ))
do
    case "${1,,}" in
        nginx) run_nginx;;
        *) show_help;;
    esac
    shift
done

