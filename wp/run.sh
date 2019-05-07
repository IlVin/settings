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

function stop_nginx() {
    for CONTAINER_ID in $(nginx_ids)
    do
        for NET_ID in $(net_bridge_ids) $(net_adm_ids) $(net_prd_ids)
        do
            if [[ $(sudo  docker network inspect ${NET_ID} | jq '.[] | .Containers | keys | .[]' | grep -o '"${CONTAINER_ID}') != '' ]]
            then
                sudo docker network disconnect ${NET_ID} ${CONTAINER_ID}
            fi
        done
        sudo docker container stop ${CONTAINER_ID}
        sudo docker container rm ${CONTAINER_ID}
    done
}

function stop_fpm_adm() {
    for CONTAINER_ID in $(fpm_adm_ids)
    do
        for NET_ID in $(net_bridge_ids) $(net_adm_ids) $(net_prd_ids)
        do
            if [[ $(sudo  docker network inspect ${NET_ID} | jq '.[] | .Containers | keys | .[]' | grep -o '"${CONTAINER_ID}') != '' ]]
            then
                sudo docker network disconnect ${NET_ID} ${CONTAINER_ID}
            fi
        done
        sudo docker container stop ${CONTAINER_ID}
        sudo docker container rm ${CONTAINER_ID}
    done
}

function stop_fpm_prd() {
    for CONTAINER_ID in $(fpm_prd_ids)
    do
        for NET_ID in $(net_bridge_ids) $(net_adm_ids) $(net_prd_ids)
        do
            if [[ $(sudo  docker network inspect ${NET_ID} | jq '.[] | .Containers | keys | .[]' | grep -o '"${CONTAINER_ID}') != '' ]]
            then
                sudo docker network disconnect ${NET_ID} ${CONTAINER_ID}
            fi
        done
        sudo docker container stop ${CONTAINER_ID}
        sudo docker container rm ${CONTAINER_ID}
    done
}


function run_nginx() {
    IMAGE="nginx:latest"
    COMMAND='/bin/bash'

    stop_nginx

    CONTAINER_ID=$(sudo docker create \
        --name ${HOSTNAME_NGINX} \
        --rm \
        -it \
        --network=bridge \
        -e USER=${PRJ_OWNER} \
        -e GROUP=${PRJ_GROUP} \
        -v ${CONF_NGINX}:/etc/nginx/nginx.conf:ro \
        -v ${CERT_DIR}:${CERT_DIR}:ro \
        -v ${HTDOCS_DIR}:${HTDOCS_DIR}:ro \
        -v ${CACHE_DIR}/nginx/:/var/cache/nginx:rw \
        -v ${LOG_DIR_NGINX}/:/var/log/nginx/:rw \
        -v ${RUN_DIR_NGINX}/:/var/run/:rw \
        --hostname ${HOSTNAME_NGINX} \
        --publish 80:80 \
        --publish 443:443 \
        ${IMAGE} \
        ${COMMAND}
        #--read-only \
        #--network="${NET_PRD}" \
        #--network-alias ${HOSTNAME_NGINX} \
        #--link ${HOSTNAME_UNIT_ADM}:${HOSTNAME_UNIT_ADM} \
        #--detach 
    )

    for NET_ID in $(net_adm_ids) $(net_prd_ids)
    do
        sudo docker network connect ${NET_ID} ${CONTAINER_ID}
    done
    sudo docker start ${CONTAINER_ID}
}

function run_fpm_adm() {
    COMMAND='/bin/bash'

    stop_fpm_adm

    CONTAINER_ID=$(
        sudo docker create \
        --name ${HOSTNAME_FPM_ADM} \
        --rm \
        -it \
        -e USER=${USER_ADM} \
        -e GROUP=${GROUP_ADM} \
        -e FS_RO=0 \
        -e OFFLINE=0 \
        -e DB_RO=0 \
        --hostname ${HOSTNAME_FPM_ADM} \
        --network=bridge \
        --user=$(id -u ${USER_ADM}):$(id -g ${GROUP_ADM}) \
        -v /etc/passwd:/etc/passwd:ro \
        -v /etc/group:/etc/group:ro \
        -v ${HTDOCS_DIR}:${HTDOCS_DIR}:rw \
        -v ${LOG_DIR_FPM_ADM}/:/var/log/:rw \
        -v ${RUN_DIR_FPM_ADM}/:/run/php/:rw \
        ${IMG_NAME_FPM_ADM} \
        ${COMMAND}
    )

    for NET_ID in $(net_adm_ids)
    do
        sudo docker network connect ${NET_ID} ${CONTAINER_ID}
    done
    sudo docker start ${CONTAINER_ID}
    if [[ ${COMMAND} ]]
    then
        sudo docker attach ${CONTAINER_ID}
    fi

}

function run_fpm_prd() {
    IMAGE='nginx/unit:latest'
    #COMMAND='/bin/bash'

    stop_unit

    sudo rm -rf ${RUN_DIR_UNIT_PRD}/*
    sudo docker run \
        --name ${HOSTNAME_UNIT_PRD} \
        --rm \
        -it \
        -e USER=${PRJ_OWNER} \
        -e GROUP=${PRJ_GROUP} \
        -e FS_RO=1 \
        -e OFFLINE=1 \
        -e DB_RO=1 \
        --hostname ${HOSTNAME_UNIT_PRD} \
        --network=${NET_PRD} \
        --user=$(id -u ${PRJ_OWNER}):$(id -g ${PRJ_GROUP}) \
        --detach \
        -v /etc/passwd:/etc/passwd:ro \
        -v /etc/group:/etc/group:ro \
        -v ${HTDOCS_DIR}:${HTDOCS_DIR}:ro \
        -v ${STATE_DIR_UNIT_PRD}:/var/lib/unit/:rw \
        -v ${LOG_DIR_UNIT_PRD}/:/var/log/:rw \
        -v ${RUN_DIR_UNIT_PRD}/:/var/run/:rw \
        ${IMAGE} \
        ${COMMAND}

    sudo curl -X PUT --data-binary @${CONF_UNIT_PRD} --unix-socket ${RUN_DIR_UNIT_PRD}/control.unit.sock 'http://localhost/config'
    sudo curl -X GET --unix-socket ${RUN_DIR_UNIT_PRD}/control.unit.sock 'http://localhost/config'

    sudo rm -rf ${RUN_DIR_UNIT_ADM}/*
    CONTAINER_ID=$(
        sudo docker create \
        --name ${HOSTNAME_UNIT_ADM} \
        --rm \
        -it \
        -e USER=${PRJ_OWNER} \
        -e GROUP=${PRJ_GROUP} \
        -e FS_RO=0 \
        -e OFFLINE=0 \
        -e DB_RO=0 \
        --hostname ${HOSTNAME_UNIT_ADM} \
        --network=bridge \
        --user=$(id -u ${PRJ_OWNER}):$(id -g ${PRJ_GROUP}) \
        -v /etc/passwd:/etc/passwd:ro \
        -v /etc/group:/etc/group:ro \
        -v ${HTDOCS_DIR}:${HTDOCS_DIR}:rw \
        -v ${STATE_DIR_UNIT_ADM}:/var/lib/unit/:rw \
        -v ${LOG_DIR_UNIT_ADM}/:/var/log/:rw \
        -v ${RUN_DIR_UNIT_ADM}/:/var/run/:rw \
        ${IMAGE}
    )

    for NET_ID in $(net_adm_ids)
    do
        sudo docker network connect ${NET_ID} ${CONTAINER_ID}
    done
    sudo docker start ${CONTAINER_ID}

    sudo curl -X PUT --data-binary @${CONF_UNIT_ADM} --unix-socket ${RUN_DIR_UNIT_ADM}/control.unit.sock 'http://localhost/config'
    sudo curl -X GET --unix-socket ${RUN_DIR_UNIT_ADM}/control.unit.sock 'http://localhost/config'
}


function show_help() {
    echo "Unknown argument"
}

while (( $# ))
do
    case "${1,,}" in
        nginx) run_nginx;;
        fpm) run_fpm_adm;;
        *) show_help;;
    esac
    shift
done

