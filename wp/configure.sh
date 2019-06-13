#!/bin/bash -x

export DEBIAN_FRONTEND="noninteractive"

if [[ ${SET_ENV} != 'INCLUDED' ]]
then
    . ./set_env.sh
fi

umask ${UMASK}

function autoremove() {
    sudo apt-get autoremove -yqq
    sudo apt-get autoclean -yqq
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
}

function install_base () {
    sudo add-apt-repository universe
    sudo apt-get update -yqq

    sudo apt-get install -yqq \
        ca-certificates \
        apt-utils \
        software-properties-common \
        apt-transport-https

    sudo apt-get install -yqq --no-install-recommends --no-install-suggests \
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

    sudo apt-get dist-upgrade -yqq --allow-downgrades

    # Setup locales
    for LOC in ru_RU en_US
    do
        sudo locale-gen ${LOC}.UTF-8
    done
    sudo localedef ru_RU.UTF-8 -i ru_RU -f UTF-8;

    # Timezone setup
    sudo ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
    sudo dpkg-reconfigure --frontend noninteractive tzdata

    sudo ldconfig
}

function purge_web() {
    sudo apt purge -yqq nginx*
    sudo apt purge -yqq php${PHPVER}*
    sudo apt purge -yqq php-fpm${PHPVER}*

    [[ -d /etc/php ]] && sudo rm -rf /etc/php
    [[ -d /etc/nginx ]] && sudo rm -rf /etc/nginx
}

function install_web () {
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
    sudo add-apt-repository "deb http://nginx.org/packages/ubuntu/ $(LSB) nginx"

    sudo apt-get update -yqq

    sudo apt-get install -yqq --no-install-recommends --no-install-suggests \
        nginx \
        php${PHPVER} \
        php${PHPVER}-fpm \
        php${PHPVER}-opcache \
        php${PHPVER}-mysql \
        php${PHPVER}-gd \
        php${PHPVER}-json \
        php${PHPVER}-xml \
        php${PHPVER}-ssh2 \
        php${PHPVER}-oauth \
        php${PHPVER}-zip \
        php${PHPVER}-xsl \
        php${PHPVER}-xmlrpc \
        php${PHPVER}-curl
}

function configure_permissions() {
    local filename
    for filename in /etc/pam.d/common-session /etc/pam.d/common-session-noninteractive
    do
        sudo sed -i -r \
            -e "s|^(\s*session\s+optional\s+pam_umask.so).*|\1 umask=${UMASK}|g" \
            ${filename}
    done

    sudo sed -i -r \
        -e "/^\s*umask\s+[0-9]+/d" \
        -e "s|^(# php${PHPVER}-fpm - The PHP FastCGI Process Manager\s*)\$|\1\numask ${UMASK}|g" \
    /etc/init/php${PHPVER}-fpm.conf

    cat /lib/systemd/system/php${PHPVER}-fpm.service \
    | sed -r \
        -e "s|\[Service\]\s*|[Service]\nUMask=${UMASK}|g" \
    | sudo tee /etc/systemd/system/php${PHPVER}-fpm.service

    sudo systemctl daemon-reload
}

function configure_openssh() {
    [ -d ~/.ssh ] || mkdir ~/.ssh
    [ -d ~/.ssh ] && chmod 700 ~/.ssh

    # SSH Agent setup
    sudo sed -i -r \
        -e 's/#?\s*(PubkeyAuthentication)\s+(yes|no)/\1 yes/g' \
        -e 's/#?\s*(RSAAuthentication)\s+(yes|no)/\1 yes/g' \
        -e 's/#?\s*(PasswordAuthentication)\s+(yes|no)/\1 no/g' \
        -e 's/#?\s*(AllowAgentForwarding)\s+(yes|no)/\1 yes/g' \
        -e 's/#?\s*(X11Forwarding)\s+(yes|no)/\1 yes/g' \
        -e 's/#?\s*(UsePAM)\s+(yes|no)/\1 yes/g' \
        -e 's/#?\s*(UseLogin)\s+(yes|no)/\1 no/g' \
        -e 's/#?\s*(TCPKeepAlive)\s+(yes|no)/\1 yes/g' \
    /etc/ssh/sshd_config

    mkdir -p ${HOME}/.ssh
    chmod a-rwx,u+rwx ${HOME}/.ssh
    if [[ !(-f ${HOME}/.ssh/authorized_keys) || ($(grep 'rsa-key-IlVin-20150714' ${HOME}/.ssh/authorized_keys | wc -l) == 0) ]]
    then
    cat << EOF | tee -a ${HOME}/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAmiXomW7qcG3PJqhJeNs+NmmNrwN3lrBwx2hR55vS+Q5l5MR5eUdjB94ou+ag69PtVPuslVhJ8cNY4IaNeWog5T9ulSs9vSb9+7pnEws34Vy5Bu0ePE+HXGZ8EHnND4C1ljsbM49n35BxRtrjOeEkFWeNNaKqPqvwutebrg0Bu+LQLZ69xBV0dBpfDZwrsTkDePQKV9E6b26fi+tAmZEVbInT4wHyXXSDmlRlv86oF3WFpyLxKNsZsTcmJMt1Gz5kzJr4fGcAp+kE5Nzhg+E/+QOAKa/b2KPm16jMMUuazI8b6wyTwXKB7WI516gr1DJSlMqKiNQALQQJQv59q/u0jw== rsa-key-IlVin-20150714
EOF
    fi
    chmod a-rwx,u+rw ${HOME}/.ssh/authorized_keys
    sudo service sshd restart

    # Host for CA certificate manipulation
    ssh-keygen -R ca.iv77msk.ru
    ssh-keyscan ca.iv77msk.ru | tee -a ${HOME}/.ssh/known_hosts
}

function configure_hosts() {
    local IP=$(get_local_ip)
    sudo sed -r --in-place "/\\s+${PRJ_DOMAIN}/d" /etc/hosts
    echo "${IP} ${PRJ_DOMAIN}" | sudo tee -a /etc/hosts > /dev/null
    sudo hostname ${PRJ_DOMAIN}
}

function setup_group() {
    local grp=$1
    if [ `getent group ${grp}` ]
    then
        echo "Group ${grp} exists"
    else
        sudo groupadd ${grp}
    fi
}

function setup_user_group() {
    local user=$1
    local group=$2

    setup_group ${group}

    if [[ $(id -u ${user} 2>/dev/null) > 0 ]]
    then
        echo "User ${user} exists"
        sudo usermod -a -G ${group} ${user}
    else
        sudo useradd -d /dev/null -s /sbin/nologin -g ${group} ${user}
    fi
}

function setup_users_groups() {
    setup_user_group ${PRJ_OWNER} ${PRJ_GROUP}
    setup_user_group ${USER} ${PRJ_GROUP}
    setup_user_group $(whoami) ${PRJ_GROUP}

    setup_user_group ${USER_NGINX} ${GROUP_NGINX}
    setup_user_group ${USER_FPM_PRD} ${GROUP_FPM_PRD}
    setup_user_group ${USER_FPM_ADM} ${GROUP_FPM_ADM}

    setup_user_group $(whoami) ${GROUP_NGINX}
    setup_user_group $(whoami) ${GROUP_FPM_PRD}
    setup_user_group $(whoami) ${GROUP_FPM_ADM}
}

function setup_folders() {

    sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${PRJ_ROOT}

    sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${SITE_ROOT}
    sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${HTDOCS_DIR}
    sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${WP_DIR}

    sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${LOG_DIR}
    sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${CERT_DIR}
    sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${DB_DIR}
    sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${SOFT_DIR}

    sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${CACHE_DIR}
    sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${RUN_DIR}
    sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${CONF_DIR}

    sudo install -g ${GROUP_FPM_ADM} -o ${USER_FPM_ADM} -d -m a+rwx,o-w,g+s ${ROOT_FPM_ADM}
    sudo install -g ${GROUP_FPM_PRD} -o ${USER_FPM_PRD} -d -m a+rwx,o-w,g+s ${ROOT_FPM_PRD}
}

function generate_cert() {
    # https://www.opennet.ru/base/sec/ssl_cert.txt.html

    echo -e "subjectAltName=DNS:$(join_by ',DNS:' ${PRJ_DOMAINS[@]})" > ${CERT_DIR}/extfile.ini

    # ЦЕНТР СЕРТИФИКАЦИИ: сертификат + приватный ключ
    [[ -f ${CERT_CA_CRT} ]] || openssl req -new -newkey rsa:1024 -nodes \
        -keyout ${CERT_CA_KEY} \
        -x509 \
        -days 10000 \
        -subj /C=RU/ST=Msk/L=Msk/O=IlVin/OU=IlVin\ CA/CN=iv77msk.ru/emailAddress=info@iv77msk.ru \
        -out ${CERT_CA_CRT}

    # WEB-сервер: сертификат + приватный ключ
    [[ -f ${CERT_DIR}/${PRJ_DOMAIN}_server.csr ]] || openssl req -new -newkey rsa:1024 -nodes \
        -keyout ${CERT_DIR}/${PRJ_DOMAIN}_server.key \
        -subj /C=RU/ST=Msk/L=Msk/O=${PRJ_NAME}/OU=${PRJ_NAME}\ Server/CN=${PRJ_DOMAIN}/emailAddress=${PRJ_EMAIL} \
        -out ${CERT_DIR}/${PRJ_DOMAIN}_server.csr

    # Подписываем сертификат WEB-сервера нашим центром сертификации
    [[ -f ${CERT_DIR}/${PRJ_DOMAIN}_server.pem ]] || openssl x509 -req -days 10950 \
        -in ${CERT_DIR}/${PRJ_DOMAIN}_server.csr \
        -CA ${CERT_CA_CRT} \
        -CAkey ${CERT_CA_KEY} \
        -set_serial 0x`openssl rand -hex 16` \
        -sha256 \
        -extfile ${CERT_DIR}/extfile.ini \
        -out ${CERT_DIR}/${PRJ_DOMAIN}_server.pem

    # КЛИЕНТ: сертификат + приватный ключ
    [[ -f ${CERT_DIR}/${PRJ_DOMAIN}_client.csr ]] || openssl req -new -newkey rsa:1024 -nodes \
        -keyout ${CERT_DIR}/${PRJ_DOMAIN}_client.key \
        -subj /C=RU/ST=Msk/L=Msk/O=${PRJ_NAME}/OU=${PRJ_NAME}\ Client/CN=${PRJ_DOMAIN}/emailAddress=${PRJ_EMAIL} \
        -out ${CERT_DIR}/${PRJ_DOMAIN}_client.csr

    # Подписываем клиентский сертификат нашим центром сертификации.
    # openssl ca -config ca.config -in client01.csr -out client01.crt -batch
    [[ -f ${CERT_DIR}/${PRJ_DOMAIN}_client.pem ]] || openssl x509 -req -days 10950 \
        -in ${CERT_DIR}/${PRJ_DOMAIN}_client.csr \
        -CA ${CERT_CA_CRT} \
        -CAkey ${CERT_CA_KEY} \
        -set_serial 0x`openssl rand -hex 16` \
        -sha256 \
        -extfile ${CERT_DIR}/extfile.ini \
        -out ${CERT_DIR}/${PRJ_DOMAIN}_client.pem

    #  Создание сертфиката в формате PKCS#12 для браузеров
    openssl pkcs12 -export \
        -in ${CERT_DIR}/${PRJ_DOMAIN}_client.pem \
        -inkey ${CERT_DIR}/${PRJ_DOMAIN}_client.key \
        -name "Sub-domain certificate for ${PRJ_DOMAIN}" \
        -passout pass: \
        -out ${CERT_DIR}/${PRJ_DOMAIN}_client.p12

    rm -f ${CERT_DIR}/*.csr
}

# https://habr.com/ru/post/316802/
# https://qwertys.ru/?p=78 - chroot
function configure_fpm() {
    sudo sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/${PHPVER}/fpm/php-fpm.conf

    sudo sed -i "s|display_errors\s*=.*|display_errors = Off|g" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|display_startup_errors\s*=.*|display_startup_errors = Off|g" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|log_errors\s*=.*|log_errors = On|g" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|allow_url_fopen\s*=.*|allow_url_fopen = Off|g" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|allow_url_include\s*=.*|allow_url_include = Off|g" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|;*\s*date\.timezone\s*=.*|date.timezone = ${TIMEZONE}|g" /etc/php/${PHPVER}/fpm/php.ini

    sudo sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|post_max_size =.*|post_max_size = ${PHP_MAX_POST}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|;*\s*cgi\.fix_pathinfo\s*=.*|cgi.fix_pathinfo = 0|g" /etc/php/${PHPVER}/fpm/php.ini

    sudo sed -i "s|doc_root\s*=.*|doc_root = ${HTDOCS_DIR}|" /etc/php/${PHPVER}/fpm/php.ini
    #sudo sed -i "s|user_dir\s*=.*|user_dir =|g" /etc/php/${PHPVER}/fpm/php.ini

    [[ -f /etc/php/${PHPVER}/fpm/pool.d/www.conf ]] && sudo mv /etc/php/${PHPVER}/fpm/pool.d/www.conf /etc/php/${PHPVER}/fpm/example_pool.conf
}

function build_root_template() {
    echo "BUILD ROOT_TEMPLATE"

    # Create system folders
    for build_root_template_folder in /dev /etc /usr /usr/share /usr/share/zoneinfo
    do
        sudo install -g ${PRJ_OWNER} -o ${PRJ_GROUP} -d -m a+rwx,o-w,g+s ${ROOT_TEMPLATE}${build_root_template_folder}
    done
}

function make_root_fpm() {
    local root=$1
    local user=$2
    local group=$3
    local make_folders=$4
    local mount_ro_folders=$5
    local mount_rw_folders=$6
    #local mount_ro_files=$7
    #local mount_rw_files=$8
    local folder
    local file

    # Delete root folder if exists
    stop_nginx
    stop_fpm
    cat /etc/mtab | cut -f 2 -d ' ' | grep "${root}" | xargs -r sudo umount -l
    cat /etc/mtab | cut -f 2 -d ' ' | grep "${root}" | xargs -r sudo umount -f
    [[ -d ${root} || -f ${root} ]] && sudo rm -rf ${root}

    # Create system folders
    for folder in / /tmp /etc /dev /usr /var /usr/share /usr/share/zoneinfo ${make_folders}
    do
        sudo install -g ${group} -o ${user} -d -m a+rwx,g+s,o-w ${root}${folder}
    done

    # MOUNT RO system files
    for file in /dev/random /dev/urandom /etc/localtime /etc/hosts /etc/resolv.conf
    do
        [[ -f ${root}${file} ]] || sudo -u ${user} -g ${group} touch ${root}${file}
        sudo mount -o bind,ro,noexec ${file} ${root}${file}
    done

    # MOUNT RW system files
    for file in /dev/null
    do
        [[ -f ${root}${file} ]] || sudo -u ${user} -g ${group} touch ${root}${file}
        sudo mount -o bind,rw,noexec ${file} ${root}${file}
    done

    # MOUNT RO files
    for file in ${mount_ro_files}
    do
        [[ -f ${file} ]] || sudo -u ${user} -g ${group} touch ${file}
        [[ -f ${root}${file} ]] || sudo -u ${user} -g ${group} touch ${root}${file}
        sudo mount -o bind,ro,noexec ${file} ${root}${file}
    done

    # MOUNT RW files
    for file in ${mount_rw_files}
    do
        [[ -f ${file} ]] || sudo -u ${user} -g ${group} touch ${file}
        [[ -f ${root}${file} ]] || sudo -u ${user} -g ${group} touch ${root}${file}
        sudo mount -o bind,rw,noexec ${file} ${root}${file}
    done

    # MOUNT RO folders
    for folder in /usr/share/zoneinfo ${mount_ro_folders}
    do
        [[ -d ${folder} ]] || sudo -u ${user} -g ${group} mkdir -p ${folder}
        [[ -d ${root}${folder} ]] || sudo install -g ${group} -o ${user} -d -m a+rwx,g+s,o-w ${root}${folder}
        sudo mount -o bind,ro,noexec ${folder} ${root}${folder}
    done

    # MOUNT RW folders
    for folder in ${mount_rw_folders}
    do
        [[ -d ${folder} ]] || sudo -u ${user} -g ${group} mkdir -p ${folder}
        [[ -d ${root}${folder} ]] || sudo install -g ${group} -o ${user} -d -m a+rwx,g+s,o-w ${root}${folder}
        sudo mount -o bind,rw,noexec ${folder} ${root}${folder}
    done
}

function configure_fpm_adm() {
    [[ -f /etc/php/${PHPVER}/fpm/example_pool.conf ]] && sudo cp -f /etc/php/${PHPVER}/fpm/example_pool.conf /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf
    setup_user_group ${USER_FPM_ADM} ${GROUP_FPM_ADM}

    sudo sed -i -r \
        -e "s|^\s*\[www\]|[${PRJ_NAME}_adm]|g" \
        -e "s|^;*\s*user\s*=.*|user = ${USER_FPM_ADM}|g" \
        -e "s|^;*\s*group\s*=.*|group = ${GROUP_FPM_ADM}|g" \
        -e "s|^;*\s*listen\s*=.*|listen = ${SOCK_FPM_ADM}|g" \
        -e "s|^;*\s*listen\.owner\s*=.*|listen.owner = ${USER_NGINX}|g" \
        -e "s|^;*\s*listen\.group\s*=.*|listen.group = ${GROUP_NGINX}|g" \
        -e "s|^;*\s*listen\.mode\s*=.*|listen.mode = 0660|g" \
        -e "s|^;*\s*process\.priority\s*=.*|process.priority = -19|g" \
        -e "s|^;*\s*access\.log\s*=.*|access.log = ${ACCESS_LOG_FPM_ADM}|g" \
        -e "s|^;*\s*access\.format\s*=|access.format =|g" \
        -e "s|^;*\s*chroot\s*=.*|;chroot = ${ROOT_FPM_ADM}|g" \
        -e "s|^;*\s*chdir\s*=.*|chdir = ${HTDOCS_DIR}|g" \
        -e "s|^;*\s*clear_env\s*=.*|clear_env = yes|g" \
        -e "s|^;*\s*catch_workers_output\s*=.*|catch_workers_output = yes|g" \
        -e "s|^;*\s*env\[TMP\]\s*=.*|env\[TMP\] = /tmp|g" \
        -e "s|^;*\s*pm\s*=.*|pm = static|g" \
        -e "s|^;*\s*pm\.max_children\s*=.*|pm.max_children = 2|g" \
        -e "s|^;*\s*pm\.min_childrens*=.*|pm.min_children = 2|g" \
        -e "s|^;*\s*pm\.start_servers\s*=.*|pm.start_servers = 2|g" \
        -e "s|^;*\s*pm\.min_spare_servers\s*=.*|pm.min_spare_servers = 0|g" \
        -e "s|^;*\s*pm\.max_spare_servers\s*=.*|pm.max_spare_servers = 2|g" \
        -e "s|^;*\s*pm\.process_idle_timeout\s*=.*|pm.process_idle_timeout = 10s|g" \
        -e "s|^;*\s*pm\.max_requests\s*=.*|pm.max_requests = 1000|g" \
        -e "s|^;*\s*pm\.status_path\s*=.*|pm.status_path = ${STATUS_PATH_FPM_ADM}|g" \
        -e "s|^;*\s*ping\.path\s*=.*|ping.path = ${PING_PATH_FPM_ADM}|g" \
        -e "s|^;*\s*ping\.response\s*=.*|ping.response = ${PING_RESPONSE_FPM_ADM}|g" \
    /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf
}

function configure_fpm_prd() {
    [[ -f /etc/php/${PHPVER}/fpm/example_pool.conf ]] && sudo cp -f /etc/php/${PHPVER}/fpm/example_pool.conf /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf
    setup_user_group ${USER_FPM_PRD} ${GROUP_FPM_PRD}

    # make_root_fpm
        # root
        # user
        # group
        # make_folder
        # mount_ro_folders
        # mount_rw_folders
    make_root_fpm \
        ${ROOT_FPM_PRD} \
        ${USER_FPM_PRD} \
        ${GROUP_FPM_PRD} \
        "" \
        "${HTDOCS_DIR}" \
        "${LOG_DIR_FPM_PRD}"

    sudo sed -i -r \
        -e "s|^\s*\[www\]|[${PRJ_NAME}_prd]|g" \
        -e "s|^;*\s*user\s*=.*|user = ${USER_FPM_PRD}|g" \
        -e "s|^;*\s*group\s*=.*|group = ${GROUP_FPM_PRD}|g" \
        -e "s|^;*\s*listen\s*=.*|listen = ${SOCK_FPM_PRD}|g" \
        -e "s|^;*\s*listen\.owner\s*=.*|listen.owner = ${USER_NGINX}|g" \
        -e "s|^;*\s*listen\.group\s*=.*|listen.group = ${GROUP_NGINX}|g" \
        -e "s|^;*\s*listen\.mode\s*=.*|listen.mode = 0660|g" \
        -e "s|^;*\s*process\.priority\s*=.*|process.priority = -18|g" \
        -e "s|^;*\s*access\.log\s*=.*|access.log = ${ACCESS_LOG_FPM_PRD}|g" \
        -e "s|^;*\s*access\.format\s*=|access.format =|g" \
        -e "s|^;*\s*chroot\s*=.*|chroot = ${ROOT_FPM_PRD}|g" \
        -e "s|^;*\s*chdir\s*=.*|chdir = ${HTDOCS_DIR}|g" \
        -e "s|^;*\s*clear_env\s*=.*|clear_env = yes|g" \
        -e "s|^;*\s*catch_workers_output\s*=.*|catch_workers_output = yes|g" \
        -e "s|^;*\s*env\[TMP\]\s*=.*|env\[TMP\] = /tmp|g" \
        -e "s|^;*\s*pm\s*=.*|pm = dynamic|g" \
        -e "s|^;*\s*pm\.max_children\s*=.*|pm.max_children = 20|g" \
        -e "s|^;*\s*pm\.min_childrens*=.*|pm.min_children = 5|g" \
        -e "s|^;*\s*pm\.start_servers\s*=.*|pm.start_servers = 5|g" \
        -e "s|^;*\s*pm\.min_spare_servers\s*=.*|pm.min_spare_servers = 3|g" \
        -e "s|^;*\s*pm\.max_spare_servers\s*=.*|pm.max_spare_servers = 5|g" \
        -e "s|^;*\s*pm\.process_idle_timeout\s*=.*|pm.process_idle_timeout = 10s|g" \
        -e "s|^;*\s*pm\.max_requests\s*=.*|pm.max_requests = 1000|g" \
        -e "s|^;*\s*pm\.status_path\s*=.*|pm.status_path = ${STATUS_PATH_FPM_PRD}|g" \
        -e "s|^;*\s*ping\.path\s*=.*|ping.path = ${PING_PATH_FPM_PRD}|g" \
        -e "s|^;*\s*ping\.response\s*=.*|ping.response = ${PING_RESPONSE_FPM_PRD}|g" \
    /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf
}

function configure_nginx() {
    setup_user_group ${USER_NGINX} ${GROUP_NGINX}

    sudo sed -r -i \
        -e "s|^#*(\s*)#*user\s+.*|user ${USER_NGINX};\n|;" \
        -e "s|^#*(\s*)#*error_log\s+.*|\1error_log ${ERROR_LOG_NGINX} warn;|g" \
        -e "s|^#*(\s*)#*access_log\s+.*|\1access_log ${ACCESS_LOG_NGINX} main;|g" \
        -e "s|^#*(\s*)#*sendfile\s+.*|\1sendfile on;|g" \
        -e "s|^#*(\s*)#*tcp_nopush\s+.*|\1tcp_nopush on;|g" \
        -e "s|^#*(\s*)#*tcp_nodelay\s+.*|\1tcp_nodelay on;|g" \
    /etc/nginx/nginx.conf
        #-e "s|#*(\s*)#*group\s+.*||g;" \
        #-e "2 s|^|group ${GROUP_NGINX};\n|g" \


    cat << EOF | sudo tee /etc/nginx/conf.d/10_${PRJ_NAME}-ssl_settings.conf > /dev/null
EOF

    RESTRICTIONS=<<EOF
        location = /favicon.ico {
            log_not_found off;
            access_log off;
        }

        location = /robots.txt {
            allow all;
            try_files \$uri \$uri/ /index.php?\$args \@robots;
            #access_log off;
            #log_not_found off;
        }
        location @robots {
           return 200 "User-agent: *\\nDisallow: /wp-admin/\\nDisallow: /wp-admin/admin-ajax.php\\n";
        }

        location ~ /\\.(ht|git|svn) {
            deny all;
        }
EOF

    cat << EOF | sudo tee /etc/nginx/conf.d/20_${PRJ_NAME}-upstreams.conf > /dev/null
        upstream wp_adm_upstream {
            server unix:${SOCK_FPM_ADM};
        }

        upstream wp_prd_upstream {
            server unix:${SOCK_FPM_PRD};
        }
EOF

cat << EOF | sudo tee /etc/nginx/conf.d/30_${PRJ_NAME}-frontend.conf > /dev/null
        server {
            listen 80 default_server;
            listen [::]:80 default_server;
            listen 443 ssl default_server;
            listen [::]:443 ssl default_server;
            server_name ${PRJ_DOMAIN};

            root ${HTDOCS_DIR};
            index index.php;

            ## SSL Settings
            ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
            ssl_prefer_server_ciphers on;

            ssl_certificate     ${CERT_DIR}/${PRJ_DOMAIN}_server.pem;
            ssl_certificate_key ${CERT_DIR}/${PRJ_DOMAIN}_server.key;
            ssl_trusted_certificate ${CERT_CA_CRT};
            ssl_client_certificate ${CERT_CA_CRT};
            ssl_verify_client optional;
            #ssl_stapling on;
            #ssl_stapling_verify        on;

            #ssl_stapling               on;
            #ssl_trusted_certificate    /etc/nginx/certs/startssl.stapling.crt;

            location @index_php_adm {
                #try_files \$uri =404;

                fastcgi_pass unix:${SOCK_FPM_ADM};
                include fastcgi_params;
                fastcgi_index index.php;

                fastcgi_param  SCRIPT_FILENAME  \$realpath_root\$fastcgi_script_name;
                fastcgi_param  UMASK "${UMASK}";
                fastcgi_param  DB_HOST "${DB_HOST_ADM}";
                fastcgi_param  DB_PORT "${DB_PORT_ADM}";
                fastcgi_param  DB_NAME "${DB_NAME_ADM}";
                fastcgi_param  DB_USER "${DB_USER_ADM}";
                fastcgi_param  DB_PASSWORD "${DB_PASSWORD_ADM}";

                fastcgi_param  READ_ONLY "1";
                fastcgi_param  SELECT_ONLY "1";
                fastcgi_param  OFFLINE "1";
                fastcgi_param  SSL_CLIENT_I_DN "\$ssl_client_i_dn";
                fastcgi_param  SSL_CLIENT_I_DN "\$ssl_client_s_dn";
                fastcgi_param  SSL_CLIENT_VERIFY "\$ssl_client_verify";
                fastcgi_param  SSL_SERVER_NAME "\$ssl_server_name";
                fastcgi_param  SSL_SESSION_ID "\$ssl_session_id";
                fastcgi_param  SSL_SESSION_REUSED "\$ssl_session_reused";

                #gzip on;
                #gzip_comp_level 4;
                #gzip_proxied any;
            }

            location @index_php_prd {
                try_files \$uri =404;

                fastcgi_pass unix:${SOCK_FPM_PRD};
                include fastcgi_params;
                fastcgi_index index.php;

                fastcgi_param  SCRIPT_FILENAME  \$realpath_root\$fastcgi_script_name;
                fastcgi_param  UMASK "${UMASK}";
                fastcgi_param  DB_HOST "${DB_HOST_PRD}";
                fastcgi_param  DB_PORT "${DB_PORT_PRD}";
                fastcgi_param  DB_NAME "${DB_NAME_PRD}";
                fastcgi_param  DB_USER "${DB_USER_PRD}";
                fastcgi_param  DB_PASSWORD "${DB_PASSWORD_PRD}";

                fastcgi_param  READ_ONLY "1";
                fastcgi_param  SELECT_ONLY "1";
                fastcgi_param  OFFLINE "1";
                fastcgi_param  SSL_CLIENT_I_DN "\$ssl_client_i_dn";
                fastcgi_param  SSL_CLIENT_I_DN "\$ssl_client_s_dn";
                fastcgi_param  SSL_CLIENT_VERIFY "\$ssl_client_verify";
                fastcgi_param  SSL_SERVER_NAME "\$ssl_server_name";
                fastcgi_param  SSL_SESSION_ID "\$ssl_session_id";
                fastcgi_param  SSL_SESSION_REUSED "\$ssl_session_reused";

                #gzip on;
                #gzip_comp_level 4;
                #gzip_proxied any;
            }

            location / {
                error_page 418 = @index_php_adm; return 418;
                #try_files \$uri \$uri/ @index_php_adm;
            }

            location ~* \\.(js|css|png|jpg|jpeg|gif|ico)$ {
                expires max;
                log_not_found off;
            }
        }
EOF
}


function configure_mariadb() {
    sudo mysql_secure_installation
    sudo mysql -uroot -p${DB_PASSWORD} << EOF
        SHOW DATABASES;
        DROP DATABASE IF EXISTS \`${DB_NAME}\`;
        CREATE DATABASE \`${DB_NAME}\`;
        GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO ${DB_USER}@'${DB_HOST}' IDENTIFIED BY '${DB_PASSWORD}';
        FLUSH PRIVILEGES;
EOF
}

function configure_wp() {
    [ -f ${SOFT_DIR}/latest.tar.gz  ] && rm -f ${SOFT_DIR}/latest.tar.gz
    [ -f ${SOFT_DIR}/wordpress.tar.gz ] && rm -f ${SOFT_DIR}/wordpress.tar.gz
    [ -d ${WP_DIR} ] && rm -rf ${WP_DIR}/*
    cd ${SOFT_DIR} && \
    [ -f ${SOFT_DIR}/latest-ru_RU.tar.gz ] || wget https://ru.wordpress.org/latest-ru_RU.tar.gz && \
    tar -xzf ${SOFT_DIR}/latest-ru_RU.tar.gz && \
    cp -R ${SOFT_DIR}/wordpress/* ${WP_DIR}/

    [ -f ${WP_DIR}/wp-config.php ] && rm -f ${WP_DIR}/wp-config.php
    cp ${WP_DIR}/wp-config-sample.php ${WP_DIR}/wp-config.php

    sed --in-place "s/define('WP_DEBUG', false);/define('WP_DEBUG', false);\ndefine('WP_ALLOW_MULTISITE', true);/g" ${WP_DIR}/wp-config.php
    sed --in-place "s/define('DB_NAME', 'database_name_here');/define('DB_NAME', \$_SERVER['DB_NAME']);/g" ${WP_DIR}/wp-config.php
    sed --in-place "s/define('DB_USER', 'username_here');/define('DB_USER', \$_SERVER['DB_USER']);/g" ${WP_DIR}/wp-config.php
    sed --in-place "s/define('DB_PASSWORD', 'password_here');/define('DB_PASSWORD', \$_SERVER['DB_PASSWORD']);/g" ${WP_DIR}/wp-config.php
    sed --in-place "s/define('DB_HOST', 'localhost');/define('DB_HOST', \$_SERVER['DB_HOST']);/g" ${WP_DIR}/wp-config.php

    SALT=$(curl 'https://api.wordpress.org/secret-key/1.1/salt/' | LC_ALL=C sed -e ':a;N;$!ba; s/\n/\n/g; s/[^a-zA-Z0-9,._+@%-]/\\&/g')
    #echo ${SALT}
    sed --in-place -E "s/define\('AUTH_KEY',[^;]+;//g" ${WP_DIR}/wp-config.php
    sed --in-place -E "s/define\('SECURE_AUTH_KEY',[^;]+;//g" ${WP_DIR}/wp-config.php
    sed --in-place -E "s/define\('LOGGED_IN_KEY',[^;]+;//g" ${WP_DIR}/wp-config.php
    sed --in-place -E "s/define\('NONCE_KEY',[^;]+;//g" ${WP_DIR}/wp-config.php
    sed --in-place -E "s/define\('AUTH_SALT',[^;]+;//g" ${WP_DIR}/wp-config.php
    sed --in-place -E "s/define\('SECURE_AUTH_SALT',[^;]+;//g" ${WP_DIR}/wp-config.php
    sed --in-place -E "s/define\('LOGGED_IN_SALT',[^;]+;//g" ${WP_DIR}/wp-config.php
    sed --in-place -E "s/define\('NONCE_SALT',[^;]+;/SALT_PLACE/g" ${WP_DIR}/wp-config.php
    sed --in-place -E "s/SALT_PLACE/${SALT}/g" ${WP_DIR}/wp-config.php

    if [ `grep -o "add_filter('filesystem_method'" ${WP_DIR}/wp-config.php | wc -l` -eq "0" ]
    then
    sudo tee <<EOF -a ${WP_DIR}/wp-config.php > /dev/null
        if(is_admin()) {
            add_filter('filesystem_method', create_function('\$a', 'return "direct";' ));
            define( 'FS_CHMOD_DIR', 0751 );
        }
EOF
    fi

    # curl https://api.wordpress.org/secret-key/1.1/salt/
}

function create_index_php() {
    cat << EOF | tee ${HTDOCS_DIR}/index.php
<?php
    phpinfo();
    echo '<pre>';
    \$dir = "/";
    // Открыть заведомо существующий каталог и начать считывать его содержимое
    if (is_dir(\$dir)) {
        if (\$dh = opendir(\$dir)) {
            while ((\$file = readdir(\$dh)) !== false) {
                print "Файл: \$file : тип: " . filetype(\$dir . \$file) . "\n";
            }
            closedir(\$dh);
        }
    }
    \$f_hdl = fopen('/umask_test.txt', 'w');
    fwrite(\$f_hdl, 'test');
    fclose(\$f_hdl);

    echo '</pre>';
?>
EOF
}


#install_base
#purge_web
#install_web

configure_permissions

configure_openssh
configure_hosts
setup_users_groups
setup_folders
#rm -f ${CERT_DIR}/*
#generate_cert

configure_fpm
configure_fpm_adm
configure_fpm_prd
configure_nginx
create_index_php



