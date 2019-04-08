
function install_unit() {
    LSB=$(LSB)
    curl 'https://nginx.org/keys/nginx_signing.key' > ~/nginx_signing.key
    sudo apt-key add ~/nginx_signing.key
    sudo add-apt-repository "deb https://packages.nginx.org/unit/ubuntu/ ${LSB} unit"
    sudo add-apt-repository "deb-src https://packages.nginx.org/unit/ubuntu/ ${LSB} unit"
    sudo apt update
    sudo apt purge -y unit.*
    sudo apt purge -y php.*
    sudo apt install -y \
        unit-php \
        unit-go1.10 \
        unit-perl \
        unit-dev \
        php-mysql \
        php-gd \
        php-json \
        php-xml \
        php-ssh2 \
        php-oauth \
        #php-fpm \
        #unit-ruby \
        #unit-jsc-common \
        #unit-jsc8 \
        #unit-jsc10 \
        #unit-python2.7 \
        #unit-python3.6 \
        #unit-go1.9 \

    #sudo service unit restart
    #cd /usr/share/doc/unit-jsc10/examples
    #sudo curl -X PUT --data-binary @unit.config --unix-socket /var/run/control.unit.sock http://localhost/config
    #curl http://localhost:8800/

}

function build_container() {
    RELEASE=$(RELEASE)
    CONTAINER_DIR=$(WORK_DIR)/container
    mkdir -p ${CONTAINER_DIR}

cat << EOF > ${CONTAINER_DIR}/install.sh
#!/bin/bash -x

    export DEBIAN_FRONTEND=noninteractive

    apt-get update -yqq

    apt-get install -yqq --no-install-recommends --no-install-suggests \
        ca-certificates \
        bash \
        apt-utils \
        apt-transport-https \
        software-properties-common \
        tzdata \
        locales \
        lsb-core \
        gnupg1 \
        gnupg2 \
        curl \

    apt-get dist-upgrade -yqq --allow-downgrades
    apt-get autoremove -yqq
    apt-get autoclean -yqq
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

    # Setup locales
    for LOC in ru_RU en_US
    do
        locale-gen \${LOC}.UTF-8
    done
    localedef ru_RU.UTF-8 -i ru_RU -f UTF-8;

    # Timezone setup
    ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata

    ldconfig
EOF
    chmod a+x ${CONTAINER_DIR}/install.sh

cat << EOF > ${CONTAINER_DIR}/Dockerfile
    #FROM ubuntu:latest
    #FROM phusion/baseimage:latest
    #FROM nginx/unit:latest
    FROM debian:stretch-slim
    MAINTAINER Ilia Vinokurov <ilvin@iv77msk.ru>

    ADD ./ /container

    RUN /container/install.sh

EOF

    RETPATH=$(pwd)
    cd ${CONTAINER_DIR} && sudo docker build -t container:v001 ./
    cd ${RETPATH}
    sudo docker image ls
}


function install_yii() {
    # Yii
    cd ~ && curl -sS https://getcomposer.org/installer | php
    cd ~ && sudo mv composer.phar /usr/local/bin/composer
}


function install_php() {
    sudo apt purge -y php.*
    sudo apt install -y \
        php-mysql \
        php-gd \
        php-json \
        php-xml \
        php-ssh2 \
        php-oauth \
        php-fpm \

}
