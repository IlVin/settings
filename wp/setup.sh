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
    sudo apt update -yqq

    sudo apt install -yqq \
        apt-utils \
        apt-transport-https \
        software-properties-common \
        ca-certificates \

    sudo apt dist-upgrade -yqq --allow-downgrades
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

    # Docker
    sudo apt purge -yqq docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${LSB} stable"

    sudo apt install -yqq docker-ce docker-ce-cli containerd.io
    sudo apt-cache madison docker-ce

    [[ $(getent group docker) ]] || sudo groupadd docker
    sudo usermod -aG docker ${USER}
    #sudo gpasswd -a ${USER} docker
    sudo systemctl enable docker.service
    sudo systemctl --no-pager status docker
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

function install_nginx() {
    LSB=$(LSB)
    # Add nginx repository
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
    sudo add-apt-repository "deb http://nginx.org/packages/ubuntu/ ${LSB} nginx"

    sudo apt purge -yqq nginx.*
    sudo apt install -yqq \
        nginx \

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

set_timezone
set_locales
install_tools
apt_upgrade
install_mariadb
install_nginx
install_docker
#install_unit
#install_yii
#build_container
#build_unit_container
#build_nginx_unit_container
#run_nginx_unit_container

sudo apt autoremove -yqq

exit




