#!/bin/bash -x

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

function run_unit_container() {
    IMAGE=unit_container:v001
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

