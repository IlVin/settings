#!/bin/sh

LSB=`lsb_release -s -c`

sudo apt update
sudo apt upgrade -y

sudo apt install -y \
    apt-utils \
    apt-transport-https \
    software-properties-common \

sudo apt dist-upgrade -y

# Timezone setup
sudo ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
sudo dpkg-reconfigure -f noninteractive tzdata

# Setup locales
for loc in ru_RU en_US
do
    [ -n "$(sudo locale -a 2>/dev/null | grep -i $loc.utf8)" ] || sudo localedef $loc.UTF-8 -i $loc -f UTF-8;
done

sudo ldconfig

# Add nginx repository
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
sudo add-apt-repository "deb http://nginx.org/packages/ubuntu/ ${LSB} nginx"

# Add mariadb repository
# https://downloads.mariadb.org/mariadb/repositories/
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
#sudo add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://mirror.mephi.ru/mariadb/repo/10.3/ubuntu ${LSB} main"
sudo add-apt-repository "deb [arch=amd64] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu ${LSB} main"


sudo apt update

PKG_LIST=" \
    vim \
    mc \
    nginx \
    apache2-utils \
    mariadb-server \
    mariadb-client \
    php-fpm \
    php-mysql \
    php-gd \
    php-json \
    php-xml \
    php-ssh2 \
    php-oauth \
    bash \
    dbus \
    sudo \
    curl \
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
"

sudo apt purge -y php.* 
sudo apt purge -y nginx.* 
sudo apt purge -y mariadb.* 

sudo apt install -y ${PKG_LIST}

sudo apt autoremove -y

# OpenSSH
[ -d ~/.ssh ] || mkdir ~/.ssh
[ -d ~/.ssh ] && chmod 700 ~/.ssh

# Yii
cd ~ && curl -sS https://getcomposer.org/installer | php
cd ~ && sudo mv composer.phar /usr/local/bin/composer

