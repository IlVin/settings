#!/bin/bash

function WORK_DIR() {
    echo "${HOME}/ilvin.git/wp"
}


function LSB() {
    lsb_release -s -c
}

function RELEASE() {
    lsb_release -r | sed -r 's/Release:\s+//'
}

function apt_upgrade() {
    sudo apt update
    sudo apt upgrade -y

    sudo apt install -y \
        apt-utils \
        apt-transport-https \
        software-properties-common \
        ca-certificates \

    sudo apt dist-upgrade -y
    sudo ldconfig
}

function set_timezone() {
    # Timezone setup
    sudo ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
    sudo dpkg-reconfigure -f noninteractive tzdata
    sudo ldconfig
}

function set_locales() {
    # Setup locales
    for loc in ru_RU en_US
    do
        [[ -n "$(sudo locale -a 2>/dev/null | grep -i $loc.utf8)" ]] || sudo localedef $loc.UTF-8 -i $loc -f UTF-8;
    done
    sudo ldconfig
}

function install_nginx() {
    LSB=$(LSB)
    # Add nginx repository
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
    sudo add-apt-repository "deb http://nginx.org/packages/ubuntu/ ${LSB} nginx"
    sudo apt update
    sudo apt purge -y nginx.*
    sudo apt install -y \
        nginx \

}

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

function install_mariadb() {
    LSB=$(LSB)
    # Add mariadb repository
    # https://downloads.mariadb.org/mariadb/repositories/
    sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
    #sudo add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://mirror.mephi.ru/mariadb/repo/10.3/ubuntu ${LSB} main"
    sudo add-apt-repository "deb [arch=amd64] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu ${LSB} main"
    sudo apt update
    sudo apt purge -y mariadb.*
    sudo apt install -y \
        mariadb-server \
        mariadb-client \

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

function install_tools() {
    sudo apt install -y \
        curl \
        vim \
        mc \
        apache2-utils \
        bash \
        dbus \
        sudo \
        wget \
        rsync \
        jq \
        dialog \
        libxml2-dev \
        libxslt1-dev \
        git \
        subversion \
        subversion-tools \
        git-svn \
        ack-grep \
        apt-file \
        atop \
        htop \
        colordiff \
        daemon \
        dnsutils \
        dupload \
        build-essential \
        gdb \
        gnupg-agent \
        info \
        iputils-ping \
        less \
        locate \
        man-db \
        pv \
        parallel \
        liblz4-tool \
        tmux \
        psmisc \
        sockstat \
        tcpdump \
        telnet \
        time \
        traceroute \
        emacs \
        whois \
        athena-jot \
        socat \
        binutils \
        coreutils \
        net-tools \
        ntp \
        make \
        cmake \
        zip \
        unzip \
        bzip2 \
        openssh-server \
        autossh \

}

function install_yii() {
    # Yii
    cd ~ && curl -sS https://getcomposer.org/installer | php
    cd ~ && sudo mv composer.phar /usr/local/bin/composer
}

function install_docker() {
    LSB=$(LSB)
    # Docker
    sudo apt purge -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${LSB} stable"

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo apt-cache madison docker-ce
    sudo usermod -aG docker $(whoami)
    sudo systemctl --no-pager status docker
}

function build_container() {
    RELEASE=$(RELEASE)
    CONTAINER_DIR=$(WORK_DIR)/container
    mkdir -p ${CONTAINER_DIR}

cat << EOF > ${CONTAINER_DIR}/install.sh
#!/bin/bash -x

    export DEBIAN_FRONTEND=noninteractive

    apt-get update -qq

    apt-get install -y --no-install-recommends --no-install-suggests \
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

    apt-get dist-upgrade -y --allow-downgrades
    apt-get autoremove -y
    apt-get autoclean -y
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
    FROM ubuntu:latest
    #FROM phusion/baseimage:latest
    #FROM nginx/unit:latest
    #FROM debian:stretch-slim
    MAINTAINER Ilia Vinokurov <ilvin@iv77msk.ru>

    ADD ./ /container

    RUN /container/install.sh

EOF

    RETPATH=$(pwd)
    cd ${CONTAINER_DIR} && sudo docker build -t container:v001 ./
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
    add-apt-repository "deb-src https://packages.nginx.org/unit/ubuntu/ \${LSB} unit"
    apt install -y \
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

    apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/unit.list

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

#apt_upgrade
#set_timezone
#set_locales
#install_tools
#install_nginx
#install_unit
#install_mariadb
#install_yii
#install_docker
#build_container
build_unit_container
run_unit_container
#sudo apt autoremove -y

exit




