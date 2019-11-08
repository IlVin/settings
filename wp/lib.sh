
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

function build_base_image() {
    IMAGE_DIR=${IMG_DIR_BASE}
    cat << EOF > ${IMAGE_DIR}/install.sh
#!/bin/bash -x
    LSB=\$(lsb_release -s -c)

    export DEBIAN_FRONTEND="noninteractive"

    apt-get update -yqq

    apt-get install -yqq \
        ca-certificates \
        apt-utils \
        software-properties-common \
        apt-transport-https \

    add-apt-repository universe

    # Add nginx repository
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
    sudo add-apt-repository "deb http://nginx.org/packages/ubuntu/ \${LSB} nginx"

    sudo apt purge -yqq nginx.*

    apt-get install -yqq --no-install-recommends --no-install-suggests \
        bash \
        sudo \
        dialog \
        tzdata \
        locales \
        lsb-core \
        gnupg1 \
        gnupg2 \
        curl \
        dnsutils \
        net-tools \
        vim \
        nginx \
        php${PHPVER} \
        php${PHPVER}-fpm \
        php${PHPVER}-zip \
        php${PHPVER}-opcache \
        php${PHPVER}-mysql \
        php${PHPVER}-gd \
        php${PHPVER}-json \
        php${PHPVER}-xml \
        php${PHPVER}-xsl \
        php${PHPVER}-xmlrpc \
        php${PHPVER}-curl \

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
    chmod a+x ${IMAGE_DIR}/install.sh

cat << EOF > ${IMAGE_DIR}/Dockerfile
    #FROM debian:stretch-slim
    FROM ubuntu:latest
    MAINTAINER Ilia Vinokurov <ilvin@iv77msk.ru>
    ADD ./ /container
    ENV DEBIAN_FRONTEND noninteractive
    RUN /container/install.sh
EOF

    RETPATH=$(pwd)
    cd ${IMAGE_DIR} && sudo docker build -t ${IMG_NAME_BASE} ./
    cd ${RETPATH}
    sudo docker image ls
}


function install_yii() {
    # Yii
    cd ~ && curl -sS https://getcomposer.org/installer | php
    cd ~ && sudo mv composer.phar /usr/local/bin/composer
}

function build_image_nginx() {
    IMAGE_DIR=${IMG_DIR_NGINX}
    cat << EOF > ${IMAGE_DIR}/install.sh
#!/bin/bash -x

EOF
    chmod a+x ${IMAGE_DIR}/install.sh

cat << EOF > ${IMAGE_DIR}/Dockerfile
    FROM ${IMG_NAME_BASE}
    MAINTAINER Ilia Vinokurov <ilvin@iv77msk.ru>
    ADD ./ /container
    RUN /container/install.sh
EOF

    RETPATH=$(pwd)
    cd ${IMAGE_DIR} && sudo docker build -t ${IMG_NAME_NGINX} ./
    cd ${RETPATH}
    sudo docker image ls
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

function install_nginx() {
    LSB=$(LSB)
    # Add nginx repository
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
    sudo add-apt-repository "deb http://nginx.org/packages/ubuntu/ ${LSB} nginx"

    sudo apt purge -yqq nginx.*
    sudo apt install -yqq \
        nginx \

}

function build_nginx_unit_container() {
    RELEASE=$(RELEASE)
    IMAGE='nginx_unit_container'
    CONTAINER_DIR=$(WORK_DIR)/${IMAGE}
    mkdir -p ${CONTAINER_DIR}

cat << EOF > ${CONTAINER_DIR}/install.sh
#!/bin/bash -x

    export DEBIAN_FRONTEND=noninteractive
    export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

    apt-get update -yqq

    apt install -yqq \
        curl \
        jq \

    #service unit restart
    #cd /usr/share/doc/unit-jsc10/examples
    #curl -X PUT --data-binary @unit.config --unix-socket /var/run/control.unit.sock http://localhost/config
    #curl http://localhost:8800/

    apt-get autoremove -yqq && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/unit.list

    #ln -sf /dev/stdout /var/log/unit.log
    rm -f /var/log/unit.log
EOF

    chmod a+x ${CONTAINER_DIR}/install.sh


cat << EOF > ${CONTAINER_DIR}/config.json
    {
        "settings": {
            "http": {
                "header_read_timeout": 10,
                "body_read_timeout": 10,
                "send_timeout": 10,
                "idle_timeout": 120,
                "max_body_size": 6291456
            }
        },
        "listeners": {
            "*:8080": {
                "pass": "applications/prod"
            },
            "*:8081": {
                "pass": "applications/dev"
            }
        },
        "applications": {
            "prod": {
                "type": "php",
                "processes": 20,
                "root": "/www/prod/",
                "index": "index.php"
            },
            "dev": {
                "type": "php",
                "processes": 3,
                "root": "/www/dev/",
                "index": "index.php"
            }
        }
    }
EOF

cat << EOF > ${CONTAINER_DIR}/start.sh
#!/bin/bash -x
    /usr/sbin/unitd --no-daemon --control unix:/var/run/control.unit.sock &>>/var/log/unit.log &
    curl -X PUT -d @/${IMAGE}/config.json  \
       --unix-socket /var/run/control.unit.sock http://localhost/config/ \
       &>>/var/log/unit_configure.log
EOF

    chmod a+x ${CONTAINER_DIR}/start.sh

cat << EOF > ${CONTAINER_DIR}/Dockerfile
    FROM nginx/unit
    MAINTAINER Ilia Vinokurov <ilvin@iv77msk.ru>

    ENV UNIT_VERSION          1.8.0-1~stretch
    ADD ./ /${IMAGE}

    RUN /${IMAGE}/install.sh

    STOPSIGNAL SIGTERM

    CMD ["${CONTAINER_DIR}/start.sh"]

EOF

    mkdir -p ${CONTAINER_DIR}/www/prod/htdocs
    mkdir -p ${CONTAINER_DIR}/www/dev/htdocs

    RETPATH=$(pwd)
    cd ${CONTAINER_DIR} && sudo docker build -t ${IMAGE}:v001 ./
    cd ${RETPATH}
    sudo docker image ls

}

function build_unit_container() {
    RELEASE=$(RELEASE)
    CONTAINER_DIR=$(WORK_DIR)/unit_container
    mkdir -p ${CONTAINER_DIR}

cat << EOF > ${CONTAINER_DIR}/install.sh
#!/bin/bash -x

    export DEBIAN_FRONTEND=noninteractive
    export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

    LSB=\$(lsb_release -s -c)
    curl 'https://nginx.org/keys/nginx_signing.key' > /unit_container/nginx_signing.key
    apt-key add /unit_container/nginx_signing.key
    add-apt-repository "deb https://packages.nginx.org/unit/ubuntu/ \${LSB} unit"

    apt-get update -yqq

    apt install -yqq \
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
        curl \
        #php-fpm \
        #unit-ruby \
        #unit-jsc-common \
        #unit-jsc8 \
        #unit-jsc10 \
        #unit-python2.7 \
        #unit-python3.6 \
        #unit-go1.9 \

    #service unit restart
    #cd /usr/share/doc/unit-jsc10/examples
    #curl -X PUT --data-binary @unit.config --unix-socket /var/run/control.unit.sock http://localhost/config
    #curl http://localhost:8800/

    apt-get autoremove -yqq && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/unit.list

    ln -sf /dev/stdout /var/log/unit.log
EOF

    chmod a+x ${CONTAINER_DIR}/install.sh

cat << EOF > ${CONTAINER_DIR}/Dockerfile
    FROM container:v001
    MAINTAINER Ilia Vinokurov <ilvin@iv77msk.ru>

    ENV UNIT_VERSION          1.8.0-1~stretch
    ADD ./ /unit_container

    RUN /unit_container/install.sh

    STOPSIGNAL SIGTERM

    CMD ["unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock"]

EOF

    RETPATH=$(pwd)
    cd ${CONTAINER_DIR} && sudo docker build -t unit_container:v001 ./
    cd ${RETPATH}
    sudo docker image ls
}

########################
#    PHP               #
########################
function configure_php() {
    sudo sed -i 's/^;cgi\.fix_pathinfo=1/cgi\.fix_pathinfo=0/g' /etc/php/7.2/fpm/php.ini
    sudo sed -i "s/^user = www-data/user = ${PHP_USER}/g" /etc/php/7.2/fpm/pool.d/www.conf
    sudo sed -i "s/^group = www-data/group = ${GROUP}/g" /etc/php/7.2/fpm/pool.d/www.conf

    sudo sed -i "s/^listen.owner = www-data/listen.owner = ${PHP_USER}/g" /etc/php/7.2/fpm/pool.d/www.conf
    sudo sed -i "s/^listen.group = www-data/listen.group = ${GROUP}/g" /etc/php/7.2/fpm/pool.d/www.conf
}

