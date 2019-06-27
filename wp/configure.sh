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
    echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
    sudo apt-get install -yqq

    sudo add-apt-repository universe
    sudo apt-get update -yqq

    sudo apt-get install -yqq \
        ca-certificates \
        dialog \
        apt-utils \
        software-properties-common \
        apt-transport-https

    sudo apt-get install -yqq --no-install-recommends --no-install-suggests \
        tzdata \
        locales \
        lsb-core \
        gnupg1 \
        gnupg2 \
        curl \
        dnsutils \
        net-tools \
        vim \

    #sudo apt-get dist-upgrade -yqq --allow-downgrades

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

    sudo service nginx stop
    sudo service php7.2-fpm stop

    sudo apt-get purge -yqq nginx*
    sudo apt-get purge -yqq php${PHPVER}*
    sudo apt-get purge -yqq php-fpm${PHPVER}*
    sudo apt purge -yqq mariadb.*

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

function install_mariadb() {
    # https://downloads.mariadb.org/mariadb/repositories/
    sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
    #sudo add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://mirror.mephi.ru/mariadb/repo/10.3/ubuntu $(LSB) main"
    sudo add-apt-repository "deb [arch=amd64] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu $(LSB) main"

    sudo apt install -yqq \
        mariadb-server \
        mariadb-client \

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
        echo "Add group ${group}"
        sudo groupadd ${grp}
    fi
}

function setup_user_group() {
    local user=$1
    local group=$2

    setup_group ${group}

    if [[ $(id -u ${user} 2>/dev/null) > 0 ]]
    then
        echo "Add user ${user} to group ${group}"
        sudo usermod -a -G ${group} ${user}
    else
        echo "Add user ${user}:${group}"
        sudo useradd -d /dev/null -s /sbin/nologin -g ${group} ${user}
    fi
}

function setup_users_groups() {
    for user_for_delete in ${PRJ_OWNER} ${USER_NGINX} ${USER_FPM_PRD} ${USER_FPM_ADM}
    do
        if [[ $(id -u ${user_for_delete} 2>/dev/null) > 0 ]]
        then
            echo "Delete user ${user_for_delete}"
            local user_home=$(grep ${user_for_delete} /etc/passwd | cut -d ':' -f 6)
            sudo userdel ${user_for_delete}
            [[ -d ${user_home} ]] && sudo rm -rf ${user_home}
        fi
    done

    for group_for_delete in ${PRJ_GROUP} ${GROUP_NGINX} ${GROUP_FPM_PRD} ${GROUP_FPM_ADM}
    do
        if [ `getent group ${group_for_delete}` ]
        then
            echo "Delete group ${group_for_delete}"
            sudo groupdel ${group_for_delete}
        fi
    done

    setup_user_group ${PRJ_OWNER} ${PRJ_GROUP}

    setup_user_group ${USER_NGINX} ${GROUP_NGINX}
    setup_user_group ${USER_FPM_PRD} ${GROUP_FPM_PRD}
    setup_user_group ${USER_FPM_ADM} ${GROUP_FPM_ADM}

    setup_user_group $(whoami) ${PRJ_GROUP}
    setup_user_group $(whoami) ${GROUP_NGINX}
    setup_user_group $(whoami) ${GROUP_FPM_PRD}
    setup_user_group $(whoami) ${GROUP_FPM_ADM}

    setup_user_group ${SERVICE_USER} ${PRJ_GROUP}
    setup_user_group ${SERVICE_USER} ${GROUP_NGINX}
    setup_user_group ${SERVICE_USER} ${GROUP_FPM_PRD}
    setup_user_group ${SERVICE_USER} ${GROUP_FPM_ADM}
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

    # Побавляем SERVICE_HOST в список известных
    user_knownhost ${SERVICE_USER} ${SERVICE_HOST}

    # Получаем CA сертификат
    curl "${CERT_CA_CERT_URL}" > ${CERT_CA_CRT}

    # WEB-сервер: сертификат + приватный ключ
    # Этот сертификат + ключ нужно купить у провайдера
    # А пока генерируем самоподписанный
    if [[ ! -f ${CERT_DIR}/${PRJ_NAME}_server.pem || ! -f ${CERT_DIR}/${PRJ_NAME}_server.key || ! -f ${CERT_DIR}/${PRJ_NAME}_admin.p12 ]]
    then
        cat << EOF | ssh ${SERVICE_USER}@${SERVICE_HOST} "/bin/bash -s" | tar -C ${CERT_DIR} -xvf -
            set -x

            CERT_DIR="\${HOME}/projects/${PRJ_NAME}"
            mkdir -p \${CERT_DIR}

            rand -s $(date +%s%N) > \${HOME}/.rnd

            echo -e "subjectAltName=DNS:$(join_by ',DNS:' ${PRJ_DOMAINS[@]})" > \${CERT_DIR}/extfile.ini

            # СЕРВЕР: Генерируем сертификат + ключ
            openssl req -new -newkey rsa:1024 -nodes \
                -keyout \${CERT_DIR}/${PRJ_NAME}_server.key \
                -subj /C=RU/ST=Msk/L=Msk/O=${PRJ_NAME}/OU=${PRJ_NAME}\ Server/CN=${PRJ_DOMAIN}/emailAddress=${PRJ_EMAIL} \
                -out \${CERT_DIR}/${PRJ_NAME}_server.csr

            # СЕРВЕР: Подписываем
            openssl x509 -req -days 36500 \
                -in \${CERT_DIR}/${PRJ_NAME}_server.csr \
                -CA \${HOME}/CA/iv77msk.ru_CA.crt \
                -CAkey \${HOME}/CA/iv77msk.ru_CA.key \
                -set_serial 0x\`openssl rand -hex 16\` \
                -sha256 \
                -extfile \${CERT_DIR}/extfile.ini \
                -out \${CERT_DIR}/${PRJ_NAME}_server.pem

            # КЛИЕНТ: сертификат + приватный ключ
            openssl req -new -newkey rsa:1024 -nodes \
                -keyout \${CERT_DIR}/${PRJ_NAME}_admin.key \
                -subj /C=RU/ST=Msk/L=Msk/O=${PRJ_NAME}/OU=${PRJ_NAME}\ Client/CN=${PRJ_DOMAIN}/emailAddress=${PRJ_EMAIL} \
                -out \${CERT_DIR}/${PRJ_NAME}_admin.csr

            # КЛИЕНТ: подписываем
            openssl x509 -req -days 36500 \
                -in \${CERT_DIR}/${PRJ_NAME}_admin.csr \
                -CA \${HOME}/CA/iv77msk.ru_CA.crt \
                -CAkey \${HOME}/CA/iv77msk.ru_CA.key \
                -set_serial 0x`openssl rand -hex 16` \
                -sha256 \
                -extfile \${CERT_DIR}/extfile.ini \
                -out \${CERT_DIR}/${PRJ_NAME}_admin.pem

            # Создание сертфиката в формате PKCS#13 для браузеров
            # PKCS #12 file that contains a user certificate, user private key, and the associated CA certificate.
            openssl pkcs12 -export \
                -in \${CERT_DIR}/${PRJ_NAME}_admin.pem \
                -inkey \${CERT_DIR}/${PRJ_NAME}_admin.key \
                -name "Sub-domain certificate for ${PRJ_NAME}" \
                -certfile \${HOME}/CA/iv77msk.ru_CA.crt \
                -caname sub-iv77msk.ru_CA \
                -passout pass: \
                -out \${CERT_DIR}/${PRJ_NAME}_admin.p12

            # Пакуем в TAR архив и отправляем на настраваемый хост
            cd \${CERT_DIR} && sudo tar --to-stdout -c \
                ${PRJ_NAME}_server.pem \
                ${PRJ_NAME}_server.key \
                ${PRJ_NAME}_admin.p12 \

EOF
        sudo chown ${USER_NGINX}:${GROUP_NGINX} ${CERT_DIR}/${PRJ_NAME}_server.key
        sudo chmod 400 ${CERT_DIR}/${PRJ_NAME}_server.key
        sudo chmod 644 ${CERT_DIR}/${PRJ_NAME}_admin.p12
    fi
}

# https://habr.com/ru/post/316802/
# https://qwertys.ru/?p=78 - chroot
function configure_fpm() {
    sudo sed -i -r \
        -e "s|;*\s*(daemonize)\s*=\s*yes|\1 = no|g" \
    /etc/php/${PHPVER}/fpm/php-fpm.conf

    sudo sed -i -r \
        -e "s|(display_errors)\s*=.*|\1 = Off|g" \
        -e "s|(display_startup_errors)\s*=.*|\1 = Off|g" \
        -e "s|(log_errors)\s*=.*|\1 = On|g" \
        -e "s|(allow_url_fopen)\s*=.*|\1 = Off|g" \
        -e "s|(allow_url_include)\s*=.*|\1 = Off|g" \
        -e "s|;*\s*(date\.timezone)\s*=.*|\1 = ${TIMEZONE}|g" \
        -e "s|(memory_limit)\s*=.*|\1 = ${PHP_MEMORY_LIMIT}|" \
        -e "s|(upload_max_filesize)\s*=.*|\1 = ${MAX_UPLOAD}|" \
        -e "s|(max_file_uploads)\s*=.*|\1 = ${PHP_MAX_FILE_UPLOAD}|" \
        -e "s|(post_max_size)\s*=.*|\1 = ${PHP_MAX_POST}|" \
        -e "s|;*\s*(cgi\.fix_pathinfo)\s*=.*|\1 = 0|g" \
        -e "s|(doc_root)\s*=.*|\1 = ${HTDOCS_DIR}|" \
    /etc/php/${PHPVER}/fpm/php.ini
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

    # MOUNT RW system folders
    for folder in /var/run/mysqld
    do
        sudo install -g ${group} -o ${user} -d -m a+rwx,g+s,o-w ${root}${folder}
        sudo mount -o bind,rw,noexec ${folder} ${root}${folder}
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
    [[ -f /etc/php/${PHPVER}/fpm/example_pool.conf ]] \
        && cp -f /etc/php/${PHPVER}/fpm/example_pool.conf ${CONF_DIR}/${PRJ_NAME}_adm.conf \
        && sudo ln -sf ${CONF_DIR}/${PRJ_NAME}_adm.conf /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf

    sudo sed -i -r \
        -e "s|^\s*\[www\]|[${PRJ_NAME}_adm]|g" \
        -e "s|^;*\s*(user)\s*=.*|\1 = ${USER_FPM_ADM}|g" \
        -e "s|^;*\s*(group)\s*=.*|\1 = ${GROUP_FPM_ADM}|g" \
        -e "s|^;*\s*(listen)\s*=.*|\1 = ${SOCK_FPM_ADM}|g" \
        -e "s|^;*\s*(listen\.owner)\s*=.*|\1 = ${USER_NGINX}|g" \
        -e "s|^;*\s*(listen\.group)\s*=.*|\1 = ${GROUP_NGINX}|g" \
        -e "s|^;*\s*(listen\.mode)\s*=.*|\1 = 0660|g" \
        -e "s|^;*\s*(process\.priority)\s*=.*|\1 = -19|g" \
        -e "s|^;*\s*(access\.log)\s*=.*|\1 = ${ACCESS_LOG_FPM_ADM}|g" \
        -e "s|^;*\s*(access\.format)\s*=|\1 =|g" \
        -e "s|^;*\s*(chroot)\s*=.*|;\1 = ${ROOT_FPM_ADM}|g" \
        -e "s|^;*\s*(chdir)\s*=.*|\1 = ${HTDOCS_DIR}|g" \
        -e "s|^;*\s*(clear_env)\s*=.*|\1 = yes|g" \
        -e "s|^;*\s*(catch_workers_output)\s*=.*|\1 = yes|g" \
        -e "s|^;*\s*(env\[TMP\])\s*=.*|\1 = /tmp|g" \
        -e "s|^;*\s*(pm)\s*=.*|\1 = static|g" \
        -e "s|^;*\s*(pm\.max_children)\s*=.*|\1 = 2|g" \
        -e "s|^;*\s*(pm\.min_childrens)*=.*|\1 = 2|g" \
        -e "s|^;*\s*(pm\.start_servers)\s*=.*|\1 = 2|g" \
        -e "s|^;*\s*(pm\.min_spare_servers)\s*=.*|\1 = 0|g" \
        -e "s|^;*\s*(pm\.max_spare_servers)\s*=.*|\1 = 2|g" \
        -e "s|^;*\s*(pm\.process_idle_timeout)\s*=.*|\1 = 10s|g" \
        -e "s|^;*\s*(pm\.max_requests)\s*=.*|\1 = 1000|g" \
        -e "s|^;*\s*(pm\.status_path)\s*=.*|\1 = ${STATUS_PATH_FPM_ADM}|g" \
        -e "s|^;*\s*(ping\.path)\s*=.*|\1 = ${PING_PATH_FPM_ADM}|g" \
        -e "s|^;*\s*(ping\.response)\s*=.*|\1 = ${PING_RESPONSE_FPM_ADM}|g" \
    ${CONF_DIR}/${PRJ_NAME}_adm.conf
}

function configure_fpm_prd() {
    [[ -f /etc/php/${PHPVER}/fpm/example_pool.conf ]] \
        && cp -f /etc/php/${PHPVER}/fpm/example_pool.conf ${CONF_DIR}/${PRJ_NAME}_prd.conf \
        && sudo ln -sf ${CONF_DIR}/${PRJ_NAME}_prd.conf /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf

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
        -e "s|^;*\s*(user)\s*=.*|\1 = ${USER_FPM_PRD}|g" \
        -e "s|^;*\s*(group)\s*=.*|\1 = ${GROUP_FPM_PRD}|g" \
        -e "s|^;*\s*(listen)\s*=.*|\1 = ${SOCK_FPM_PRD}|g" \
        -e "s|^;*\s*(listen\.owner)\s*=.*|\1 = ${USER_NGINX}|g" \
        -e "s|^;*\s*(listen\.group)\s*=.*|\1 = ${GROUP_NGINX}|g" \
        -e "s|^;*\s*(listen\.mode)\s*=.*|\1 = 0660|g" \
        -e "s|^;*\s*(process\.priority)\s*=.*|\1 = -18|g" \
        -e "s|^;*\s*(access\.log)\s*=.*|\1 = ${ACCESS_LOG_FPM_PRD}|g" \
        -e "s|^;*\s*(access\.format)\s*=|\1 =|g" \
        -e "s|^;*\s*(chroot)\s*=.*|\1 = ${ROOT_FPM_PRD}|g" \
        -e "s|^;*\s*(chdir)\s*=.*|\1 = ${HTDOCS_DIR}|g" \
        -e "s|^;*\s*(clear_env)\s*=.*|\1 = yes|g" \
        -e "s|^;*\s*(catch_workers_output)\s*=.*|\1 = yes|g" \
        -e "s|^;*\s*(env\[TMP\])\s*=.*|\1 = /tmp|g" \
        -e "s|^;*\s*(pm)\s*=.*|\1 = dynamic|g" \
        -e "s|^;*\s*(pm\.max_children)\s*=.*|\1 = 20|g" \
        -e "s|^;*\s*(pm\.min_children)\s*=.*|\1 = 5|g" \
        -e "s|^;*\s*(pm\.start_servers)\s*=.*|\1 = 5|g" \
        -e "s|^;*\s*(pm\.min_spare_servers)\s*=.*|\1 = 3|g" \
        -e "s|^;*\s*(pm\.max_spare_servers)\s*=.*|\1 = 5|g" \
        -e "s|^;*\s*(pm\.process_idle_timeout)\s*=.*|\1 = 10s|g" \
        -e "s|^;*\s*(pm\.max_requests)\s*=.*|\1 = 1000|g" \
        -e "s|^;*\s*(pm\.status_path)\s*=.*|\1 = ${STATUS_PATH_FPM_PRD}|g" \
        -e "s|^;*\s*(ping\.path)\s*=.*|\1 = ${PING_PATH_FPM_PRD}|g" \
        -e "s|^;*\s*(ping\.response)\s*=.*|\1 = ${PING_RESPONSE_FPM_PRD}|g" \
    ${CONF_DIR}/${PRJ_NAME}_prd.conf
}

function configure_nginx() {

    sudo sed -r -i \
        -e "s|^#*(\s*)#*(user)\s+.*|\2 ${USER_NGINX};|;" \
        -e "s|^#*(\s*)#*(worker_processes)\s+.*|\2 1;|;" \
        -e "s|^#*(\s*)#*(error_log)\s+.*|\1\2 ${ERROR_LOG_NGINX} warn;|g" \
        -e "s|^#*(\s*)#*(access_log)\s+.*|\1\2 ${ACCESS_LOG_NGINX} main;|g" \
        -e "s|^#*(\s*)#*(sendfile)\s+.*|\1\2 on;|g" \
        -e "s|^#*(\s*)#*(tcp_nopush)\s+.*|\1\2 on;|g" \
        -e "s|^#*(\s*)#*(tcp_nodelay)\s+.*|\1\2 on;|g" \
        -e "s|^#*(\s*)#*(gzip)\s+.*|\1\2 on;|g" \
    /etc/nginx/nginx.conf
        #-e "s|#*(\s*)#*group\s+.*||g;" \
        #-e "2 s|^|group ${GROUP_NGINX};\n|g" \

    cat << EOF | tee ${CONF_NGINX_FCGI_ADM} > /dev/null
                fastcgi_pass ${PRJ_NAME}_adm_upstream;
                include fastcgi_params;
                fastcgi_index index.php;

                fastcgi_param  SCRIPT_FILENAME  \$realpath_root\$fastcgi_script_name;
                fastcgi_param  UMASK "${UMASK}";
                fastcgi_param  DB_HOST_WP "${DB_HOST_ADM}";
                fastcgi_param  DB_USER_WP "${DB_USER_ADM}";
                fastcgi_param  DB_PASSWORD_WP "${DB_PASSWORD_ADM}";
                fastcgi_param  DB_NAME_WP "${DB_NAME_WP}";

                fastcgi_param  FSMODE "RW";
                fastcgi_param  DBMODE "FULL";
                fastcgi_param  NETWORK "ON";
                fastcgi_param  SENDMAIL "ON";
                fastcgi_param  SSL_CLIENT_I_DN "\$ssl_client_i_dn";
                fastcgi_param  SSL_CLIENT_I_DN "\$ssl_client_s_dn";
                fastcgi_param  SSL_CLIENT_VERIFY "\$ssl_client_verify";
                fastcgi_param  SSL_SERVER_NAME "\$ssl_server_name";
                fastcgi_param  SSL_SESSION_ID "\$ssl_session_id";
                fastcgi_param  SSL_SESSION_REUSED "\$ssl_session_reused";
EOF

    cat << EOF | tee ${CONF_NGINX_FCGI_PRD} > /dev/null
                fastcgi_pass ${PRJ_NAME}_prd_upstream;
                include fastcgi_params;
                fastcgi_index index.php;

                fastcgi_param  SCRIPT_FILENAME  \$realpath_root\$fastcgi_script_name;
                fastcgi_param  UMASK "${UMASK}";
                fastcgi_param  DB_HOST_WP "${DB_HOST_PRD}";
                fastcgi_param  DB_USER_WP "${DB_USER_PRD}";
                fastcgi_param  DB_PASSWORD_WP "${DB_PASSWORD_PRD}";
                fastcgi_param  DB_NAME_WP "${DB_NAME_WP}";

                fastcgi_param  FSMODE "RO";
                fastcgi_param  DBMODE "LIMITED";
                fastcgi_param  NETWORK "OFF";
                fastcgi_param  SENDMAIL "OFF";
                fastcgi_param  SSL_CLIENT_I_DN "\$ssl_client_i_dn";
                fastcgi_param  SSL_CLIENT_I_DN "\$ssl_client_s_dn";
                fastcgi_param  SSL_CLIENT_VERIFY "\$ssl_client_verify";
                fastcgi_param  SSL_SERVER_NAME "\$ssl_server_name";
                fastcgi_param  SSL_SESSION_ID "\$ssl_session_id";
                fastcgi_param  SSL_SESSION_REUSED "\$ssl_session_reused";
EOF

    cat << EOF | tee ${CONF_NGINX} > /dev/null
        upstream ${PRJ_NAME}_adm_upstream {
            server unix:${SOCK_FPM_ADM};
        }

        upstream ${PRJ_NAME}_prd_upstream {
            server unix:${SOCK_FPM_PRD};
        }

        server {
            listen 80 ;
            listen [::]:80 ;
            server_name _;
            return 301 https://${PRJ_DOMAIN}$request_uri;
        }

        server {
            listen 443 ssl default_server;
            listen [::]:443 ssl default_server;
            server_name ${PRJ_DOMAIN};

            root ${HTDOCS_DIR};
            index index.php;

            ## SSL Settings
            ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
            ssl_prefer_server_ciphers on;

            ssl_certificate     ${CERT_DIR}/${PRJ_NAME}_server.pem;
            ssl_certificate_key ${CERT_DIR}/${PRJ_NAME}_server.key;
            ssl_trusted_certificate ${CERT_CA_CRT};
            ssl_client_certificate ${CERT_CA_CRT};
            ssl_verify_client optional;

            location @index_php_adm {
                #try_files \$uri =404;
                include ${CONF_NGINX_FCGI_ADM};
            }

            location @index_php_prd {
                #try_files \$uri =404;
                include ${CONF_NGINX_FCGI_PRD};

            }

            location = /favicon.ico {
                log_not_found off;
                access_log off;
            }

            location ~* \\.(js|css|png|jpg|jpeg|gif|ico)$ {
                expires max;
                log_not_found off;
            }

            location = /robots.txt {
                allow all;
                try_files \$uri \@robots;
                #try_files \$uri \$uri/ /index.php?\$args \@robots;
                #access_log off;
                #log_not_found off;
            }

            location @robots {
               return 200 "User-agent: *\\nDisallow: /wp-admin/\\nDisallow: /wp-admin/admin-ajax.php\\n";
            }

            location ~ /\\.(ht|git|svn) {
                deny all;
            }


            location / {
                if (\$ssl_client_verify = 'SUCCESS') {
                    error_page 418 = @index_php_adm; return 418;
                }
                error_page 418 = @index_php_prd; return 418;
                #try_files \$uri \$uri/ @index_php_adm;
            }
        }
EOF
    chmod 0664 ${CONF_NGINX}
    sudo ln -sf ${CONF_NGINX}  /etc/nginx/conf.d/${PRJ_NAME}_nginx.conf
    sudo rm -f /etc/nginx/conf.d/default.conf
}


function configure_mariadb() {
    #sudo mysql_secure_installation
    sudo mysql --user=root --password=${DEFAULT_PASSWD} mysql << EOF
        SHOW DATABASES;
        UPDATE mysql.user SET Password = PASSWORD('${DEFAULT_PASSWD}') WHERE user = 'root';
        SET PASSWORD FOR 'root'@'::1' = PASSWORD('${DEFAULT_PASSWD}');
        DROP USER IF EXISTS ''@'localhost';
        DROP USER IF EXISTS ''@'localhost.localdomain';
        DROP USER IF EXISTS '${DB_USER_ADM}'@'${DB_HOST_ADM}';
        DROP USER IF EXISTS '${DB_USER_PRD}'@'${DB_HOST_PRD}';
        DROP USER IF EXISTS '${SERVICE_USER}'@'localhost';
        CREATE USER IF NOT EXISTS '${DB_USER_ADM}'@'${DB_HOST_ADM}' IDENTIFIED BY '${DB_PASSWORD_ADM}';
        CREATE USER IF NOT EXISTS '${DB_USER_PRD}'@'${DB_HOST_PRD}' IDENTIFIED BY '${DB_PASSWORD_PRD}';
        CREATE USER IF NOT EXISTS '${SERVICE_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD_SERVICE_USER}';
        DROP DATABASE IF EXISTS \`${DB_NAME_WP}\`;
        CREATE DATABASE IF NOT EXISTS \`${DB_NAME_WP}\`;
        GRANT SELECT,INSERT,UPDATE,DELETE,DROP,CREATE,ALTER,INDEX ON \`${DB_NAME_WP}\`.* TO '${DB_USER_ADM}'@'${DB_HOST_ADM}';
        GRANT SELECT,INSERT,UPDATE,DELETE ON \`${DB_NAME_WP}\`.* TO '${DB_USER_PRD}'@'${DB_HOST_PRD}';
        GRANT ALL PRIVILEGES ON \`${DB_NAME_WP}\`.* TO '${SERVICE_USER}'@'localhost';
        FLUSH PRIVILEGES;
EOF

    sudo sed -r -i \
        -e "s|^#*(\s*)#*(default-character-set)\s+.*|\2 = utf8|g" \
        -e "s|^#*(\s*)#*(character-set-server)\s+.*|\2 = utf8|" \
        -e "s|^#*(\s*)#*(collation-server)\s+.*|\2 = utf8_general_ci|g" \
        -e "s|^#*(\s*)#*(character_set_server)\s+.*|\2 = utf8|g" \
        -e "s|^#*(\s*)#*(collation_server)\s+.*|\2 = utf8_general_ci|g" \
    /etc/mysql/mariadb.cnf

    sudo service mysql restart
}

function configure_wp() {
    local wp_tar_fn="wordpress_${START_DATE}.tar.gz"
    [[ -f ${SOFT_DIR}/${wp_tar_fn} ]] || curl 'https://ru.wordpress.org/latest-ru_RU.tar.gz' --max-redirs 3 > ${SOFT_DIR}/${wp_tar_fn}
    [[ -d ${WP_DIR} ]] && rm -rf ${WP_DIR}
    [[ -d ${WP_DIR} ]] || mkdir -p ${WP_DIR}
    [[ -d ${SOFT_DIR}/wordpress ]] && rm -rf ${SOFT_DIR}/wordpress
    cd ${SOFT_DIR} && \
    tar -xzf ${SOFT_DIR}/${wp_tar_fn} && \
    cp -R ${SOFT_DIR}/wordpress/* ${WP_DIR}/

    [[ -f ${WP_DIR}/wp-config.php ]] && rm -f ${WP_DIR}/wp-config.php
    cp ${WP_DIR}/wp-config-sample.php ${WP_DIR}/wp-config.php

    sed --in-place -r \
        -e "s/\s*define\s*\(\s*'(DB_HOST|DB_NAME|DB_USER|DB_PASSWORD)'\s*,\s*'[^']+'\s*\)\s*;\s*/define('\1', \$_SERVER['\1_WP']);/g" \
        -e "s/\s*define\s*\(\s*'(DB_CHARSET)'\s*,\s*'[^']+'\s*\)\s*;\s*/define('\1', 'utf8');/g" \
        -e "s/\s*define\s*\(\s*'(WP_DEBUG)'\s*,[^)]+\)\s*;\s*/define('\1', true);/g" \
        -e "s/\s*(\$table_prefix)\s*=\s*'[^']+'\s*;\s*/\1 = 'wp_';/g" \
    ${WP_DIR}/wp-config.php

    SALT=$(curl 'https://api.wordpress.org/secret-key/1.1/salt/' | LC_ALL=C sed -e ':a;N;$!ba; s/\n/\n/g; s/[^a-zA-Z0-9,._+@%-]/\\&/g')

    sed --in-place -r \
        -e "/\s*define\s*\(\s*'(AUTH_KEY|SECURE_AUTH_KEY|LOGGED_IN_KEY|NONCE_KEY|AUTH_SALT|SECURE_AUTH_SALT|LOGGED_IN_SALT)'\s*,\s*'[^']+'\s*\)\s*;\s*/d" \
        -e "s/\s*define\s*\(\s*'NONCE_SALT'\s*,\s*'[^']+'\s*\)\s*;\s*/${SALT}/g" \
    ${WP_DIR}/wp-config.php

    rm -f ${WP_DIR}/{license.txt,readme.html,wp-config-sample.php}
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
    \$path = \$_SERVER['DOCUMENT_ROOT'] . '/umask_' . \$_SERVER['SSL_CLIENT_VERIFY'] . '_test.txt';
    echo 'PATH: ' . \$path . "\n";
    \$f_hdl = fopen(\$path, 'w');
    fwrite(\$f_hdl, 'test');
    fclose(\$f_hdl);

    echo '</pre>';
?>
EOF
}


#purge_web
#install_base
#install_web
#install_mariadb

configure_permissions

#configure_hosts
#setup_users_groups
setup_folders
#rm -f ${CERT_DIR}/*
#generate_cert

configure_fpm
configure_fpm_adm
configure_fpm_prd
configure_nginx
configure_mariadb
configure_wp
#create_index_php




