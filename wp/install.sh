#!/bin/bash -x

export DEBIAN_FRONTEND=noninteractive
export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

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
    sudo apt install -yqq \
        apt-utils \
        apt-transport-https \
        software-properties-common \
        ca-certificates \

    sudo apt dist-upgrade -yqq --allow-downgrades
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

function install_docker() {
    LSB=$(LSB)

    # Set kernel (-10% performance, -1% memory). It's fix of the docker's warn 'Your kernel does not support swap memory limit'
    #  cgroup_enable=memory cgroup_memory=1 swapaccount=1
    sudo sed -i -r 's/GRUB_CMDLINE_LINUX="([^"]*)cgroup_enable=[^" ]+([^"]*)"/GRUB_CMDLINE_LINUX="\1\2"/g' /etc/default/grub
    sudo sed -i -r 's/GRUB_CMDLINE_LINUX="([^"]*)  ([^"]*)"/GRUB_CMDLINE_LINUX="\1 \2"/g' /etc/default/grub
    sudo sed -i -r 's/GRUB_CMDLINE_LINUX="([^"]*)cgroup_memory=[^" ]+([^"]*)"/GRUB_CMDLINE_LINUX="\1\2"/g' /etc/default/grub
    sudo sed -i -r 's/GRUB_CMDLINE_LINUX="([^"]*)  ([^"]*)"/GRUB_CMDLINE_LINUX="\1 \2"/g' /etc/default/grub
    sudo sed -i -r 's/GRUB_CMDLINE_LINUX="([^"]*)swapaccount=[^" ]+([^"]*)"/GRUB_CMDLINE_LINUX="\1\2"/g' /etc/default/grub
    sudo sed -i -r 's/GRUB_CMDLINE_LINUX="([^"]*)  ([^"]*)"/GRUB_CMDLINE_LINUX="\1 \2"/g' /etc/default/grub
    sudo sed -i -r 's/GRUB_CMDLINE_LINUX="([^"]*) "/GRUB_CMDLINE_LINUX="\1"/g' /etc/default/grub
    sudo sed -i -r 's/GRUB_CMDLINE_LINUX="([^"]+)"/GRUB_CMDLINE_LINUX="\1 cgroup_enable=memory cgroup_memory=1 swapaccount=1"/g' /etc/default/grub
    sudo update-grub

    # Remove Docker
    sudo apt purge -yqq docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io

    # Install Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${LSB} stable"

    sudo apt install -yqq docker-ce docker-ce-cli containerd.io
    sudo apt-cache madison docker-ce

    # Add current user to docker group (Need reboot)
    [[ $(getent group docker) ]] || sudo groupadd docker
    sudo usermod -aG docker ${USER}
    #sudo gpasswd -a ${USER} docker

    sudo systemctl enable docker.service
    sudo systemctl --no-pager status docker

    # Remove all images
    sudo docker ps -aq | xargs -r sudo docker rm
    sudo docker images -aq | xargs -r sudo docker rmi
}

function install_mariadb() {
    LSB=$(LSB)
    # Add mariadb repository
    # https://downloads.mariadb.org/mariadb/repositories/
    sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
    #sudo add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://mirror.mephi.ru/mariadb/repo/10.3/ubuntu ${LSB} main"
    sudo add-apt-repository "deb [arch=amd64] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu ${LSB} main"

    sudo apt purge -yqq mariadb.*
    sudo apt install -yqq \
        mariadb-server \
        mariadb-client \

}

function install_nginx_images() {
    sudo docker pull nginx
    sudo docker pull nginx/unit
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
        openssl \
        autossh \

}

sudo apt update -yqq

set_timezone
set_locales
install_tools
apt_upgrade
install_docker
install_nginx_images
install_mariadb

sudo apt autoremove -yqq
sudo ldconfig

exit





