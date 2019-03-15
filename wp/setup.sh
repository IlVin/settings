#!/bin/bash

function LSB() {
    lsb_release -s -c
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
    curl 'https://nginx.org/keys/nginx_signing.key?_ga=2.216176149.2075491811.1552638373-1644189293.1552638373' > ~/nginx_signing.key
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
    sudo apt purge docker docker-engine docker.io containerd runc
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${LSB} stable"

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo apt-cache madison docker-ce
    sudo usermod -aG docker $(whoami)
    sudo systemctl --no-pager status docker
}

#apt_upgrade
#set_timezone
#set_locales
#install_tools
#install_nginx
#install_unit
#install_mariadb
#install_yii
install_docker
sudo apt autoremove -y

exit




