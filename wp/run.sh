#!/bin/bash -x

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
    HOSTNAME=${PRJ_DOMAIN}
    CONTAINER_NAME="${PRJ_NAME}_nginx"

    sudo docker kill ${CONTAINER_NAME}

    sudo docker run \
        --name ${CONTAINER_NAME} \
        --rm \
        -it \
        --detach \
        --network="bridge" \
        --read-only \
        -e USER=${PRJ_OWNER} \
        -e GROUP=${PRJ_GROUP} \
        -v ${CONF_DIR}/nginx.conf:/etc/nginx/conf.d/${PRJ_DOMAIN}.conf:ro \
        -v ${CERT_DIR}:${CERT_DIR}:ro \
        -v ${HTDOCS_DIR}:${HTDOCS_DIR}:ro \
        -v ${CACHE_DIR}/nginx/:/var/cache/nginx:rw \
        -v ${LOG_DIR_NGINX}/:/var/log/nginx/:rw \
        -v ${RUN_DIR_NGINX}/:/var/run/:rw \
        -h $HOSTNAME \
        --publish 80:80 \
        --publish 443:443 \
        ${IMAGE}
}

function run_unit() {
    IMAGE='nginx/unit:latest'
    #COMMAND='/bin/bash'

    HOSTNAME=${PRJ_DOMAIN}

    CONTAINER_NAME="${PRJ_NAME}_unit_prd"
    sudo docker container ls -f NAME=${CONTAINER_NAME} -q | xargs -r sudo docker container stop
    sudo docker run \
        --name ${CONTAINER_NAME} \
        --rm \
        -it \
        --detach \
        -e USER=${PRJ_OWNER} \
        -e GROUP=${PRJ_GROUP} \
        -e FS_RO=1 \
        -e OFFLINE=1 \
        -e DB_RO=1 \
        -h $HOSTNAME \
        --network="${PRJ_INT_NET}" \
        --user=$(id -u ${PRJ_OWNER}):$(id -g ${PRJ_GROUP}) \
        --read-only \
        -v /etc/passwd:/etc/passwd:ro \
        -v /etc/group:/etc/group:ro \
        -v ${HTDOCS_DIR}:${HTDOCS_DIR}:ro \
        -v ${STATE_DIR_UNIT_PRD}:/var/lib/unit/:rw \
        -v ${LOG_DIR_UNIT_PRD}/:/var/log/:rw \
        -v ${RUN_DIR_UNIT_PRD}/:/var/run/:rw \
        ${IMAGE} \
        ${COMMAND}

    CONTAINER_NAME="${PRJ_NAME}_unit_adm"
    sudo docker container ls -f NAME=${CONTAINER_NAME} -q | xargs -r sudo docker container stop
    sudo docker run \
        --name ${CONTAINER_NAME} \
        --rm \
        -it \
        --detach \
        -e USER=${PRJ_OWNER} \
        -e GROUP=${PRJ_GROUP} \
        -e FS_RO=0 \
        -e OFFLINE=0 \
        -e DB_RO=0 \
        -h $HOSTNAME \
        --network="bridge" \
        --user=$(id -u ${PRJ_OWNER}):$(id -g ${PRJ_GROUP}) \
        --read-only \
        -v /etc/passwd:/etc/passwd:ro \
        -v /etc/group:/etc/group:ro \
        -v ${HTDOCS_DIR}:${HTDOCS_DIR}:rw \
        -v ${STATE_DIR_UNIT_ADM}:/var/lib/unit/:rw \
        -v ${LOG_DIR_UNIT_ADM}/:/var/log/:rw \
        -v ${RUN_DIR_UNIT_ADM}/:/var/run/:rw \
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
        unit) run_unit;;
        *) show_help;;
    esac
    shift
done

