#!/bin/bash -x

export DEBIAN_FRONTEND="noninteractive"

. ./set_env.sh

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


function configure_openssh() {
    [ -d ~/.ssh ] || mkdir ~/.ssh
    [ -d ~/.ssh ] && chmod 700 ~/.ssh
}

function configure_hosts() {
    sudo sed --in-place "s/127\.0\.0\.1\s+${PRJ_DOMAIN}//g" /etc/hosts
    echo "127.0.0.1 ${PRJ_DOMAIN}" | sudo tee -a /etc/hosts > /dev/null
}

function setup_users_groups() {
    for grp in ${PRJ_GROUP}
    do
        if [ `getent group ${grp}` ]
        then
            echo "Group ${grp} exists"
        else
            sudo groupadd ${grp}
        fi
        for owner in ${PRJ_OWNER} ${USER} $(whoami)
        do
            if [[ $(id -u ${owner} 2>/dev/null) > 0 ]]
            then
                echo "User ${owner} exists"
            else
                sudo useradd -d /dev/null -s /sbin/nologin -g ${PRJ_GROUP} ${owner}
            fi
            sudo usermod -a -G ${grp} ${owner}
        done
    done

    for grp in ${GROUP_PRD}
    do
        if [ `getent group ${grp}` ]
        then
            echo "Group ${grp} exists"
        else
            sudo groupadd ${grp}
        fi
        for user in ${USER_PRD}
        do
            if [[ $(id -u ${user} 2>/dev/null) > 0 ]]
            then
                echo "User ${user} exists"
            else
                sudo useradd -d /dev/null -s /sbin/nologin -g ${grp} ${user}
            fi
        done
    done

    for grp in ${GROUP_FPM_PRD}
    do
        if [ `getent group ${grp}` ]
        then
            echo "Group ${grp} exists"
        else
            sudo groupadd ${grp}
        fi
        for user in ${USER_FPM_PRD}
        do
            if [[ $(id -u ${user} 2>/dev/null) > 0 ]]
            then
                echo "User ${user} exists"
            else
                sudo useradd -d /dev/null -s /sbin/nologin -g ${grp} ${user}
            fi
        done
    done
}

function setup_folders() {
    for VAR in PRJ_ROOT CONF_DIR HTDOCS_DIR WP_DIR DB_DIR SOFT_DIR CACHE_DIR CERT_DIR RUN_DIR LOG_DIR ROOT_DIR
    do
        sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${!VAR}
        for SUFFIX in NGINX BASE FPM FPM_ADM FPM_PRD
        do
            DIR_VAR="${VAR}_${SUFFIX}"
            if [[ ${!DIR_VAR} != '' ]]
            then
                sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${!DIR_VAR}
            fi
        done
    done
}

function generate_cert() {
    # https://www.opennet.ru/base/sec/ssl_cert.txt.html

    # ЦЕНТР СЕРТИФИКАЦИИ: сертификат + приватный ключ
    [[ -f ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_ca.crt ]] || openssl req -new -newkey rsa:1024 -nodes \
        -keyout ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_ca.key \
        -x509 \
        -days 10000 \
        -subj /C=RU/ST=Msk/L=Msk/O=${PRJ_NAME}/OU=${PRJ_NAME}\ CA/CN=${PRJ_DOMAIN}/emailAddress=${PRJ_EMAIL} \
        -out ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_ca.crt

    # WEB-сервер: сертификат + приватный ключ
    for DOMAIN in ${PRJ_DOMAINS[@]}
    do
        [[ -f ${CERT_DIR_NGINX}/${DOMAIN}_server.csr ]] || openssl req -new -newkey rsa:1024 -nodes \
            -keyout ${CERT_DIR_NGINX}/${DOMAIN}_server.key \
            -subj /C=RU/ST=Msk/L=Msk/O=${PRJ_NAME}/OU=${PRJ_NAME}\ Client/CN=${PRJ_DOMAIN}/emailAddress=${PRJ_EMAIL} \
            -out ${CERT_DIR_NGINX}/${DOMAIN}_server.csr

        # Подписываем сертификат WEB-сервера нашим центром сертификации
        [[ -f ${CERT_DIR_NGINX}/${DOMAIN}_server.pem ]] || openssl x509 -req -days 10950 \
            -in ${CERT_DIR_NGINX}/${DOMAIN}_server.csr \
            -CA ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_ca.crt \
            -CAkey ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_ca.key \
            -set_serial 0x`openssl rand -hex 16` \
            -sha256 \
            -out ${CERT_DIR_NGINX}/${DOMAIN}_server.pem
    done

    # КЛИЕНТ: сертификат + приватный ключ
    [[ -f ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_client.csr ]] || openssl req -new -newkey rsa:1024 -nodes \
        -keyout ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_client.key \
        -subj /C=RU/ST=Msk/L=Msk/O=${PRJ_NAME}/OU=${PRJ_NAME}\ Client/CN=${PRJ_DOMAIN}/emailAddress=${PRJ_EMAIL} \
        -out ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_client.csr

    # Подписываем клиентский сертификат нашим центром сертификации.
    # openssl ca -config ca.config -in client01.csr -out client01.crt -batch
    [[ -f ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_client.pem ]] || openssl x509 -req -days 10950 \
        -in ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_client.csr \
        -CA ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_ca.crt \
        -CAkey ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_ca.key \
        -set_serial 0x`openssl rand -hex 16` \
        -sha256 \
        -out ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_client.pem

    #  Создание сертфиката в формате PKCS#12 для браузеров
    openssl pkcs12 -export \
        -in ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_client.pem \
        -inkey ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_client.key \
        -name "Sub-domain certificate for ${PRJ_DOMAIN}" \
        -passout pass: \
        -out ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_client.p12
}

# https://habr.com/ru/post/316802/
# https://qwertys.ru/?p=78 - chroot
function configure_fpm() {
    sudo sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/${PHPVER}/fpm/php-fpm.conf

    sudo sed -i "s/display_errors\s*=\s*(On|Off)/display_errors = Off/" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/display_startup_errors\s*=\s*(On|Off)/display_startup_errors = Off/" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/log_errors\s*=\s*(On|Off)/log_errors = On/" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/allow_url_fopen\s*=\s*(On|Off)/allow_url_fopen = Off/" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/allow_url_include\s*=\s*(On|Off)/allow_url_include = Off/" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/;date\.timezone =.*/date.timezone = ${TIMEZONE}/" /etc/php/${PHPVER}/fpm/php.ini

    sudo sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|post_max_size =.*|post_max_size = ${PHP_MAX_POST}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/${PHPVER}/fpm/php.ini

    sudo sed -i "s|doc_root\s*=.*|doc_root = ${HTDOCS_DIR}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/user_dir\s*=.*/user_dir =/" /etc/php/${PHPVER}/fpm/php.ini

    [[ -f /etc/php/${PHPVER}/fpm/pool.d/www.conf ]] && sudo mv /etc/php/${PHPVER}/fpm/pool.d/www.conf /etc/php/${PHPVER}/fpm/example_pool.conf
}

function install_user() {
    install_user_user=$1
    install_user_group=$2
    if [ `getent group ${install_user_group}` ]
    then
        echo "Group ${install_user_group} exists"
    else
        sudo groupadd ${install_user_group}
    fi
    if [[ $(id -u ${install_user_user} 2>/dev/null) > 0 ]]
    then
        echo "User ${install_user_user} exists"
    else
        sudo useradd -d /dev/null -s /sbin/nologin -g ${install_user_group} ${install_user_user}
    fi
}

function make_sandbox() {
    make_sandbox_root=$1
    make_sandbox_user=$2
    make_sandbox_group=$3

    make_sandbox_files=(dev/random dev/urandom etc/localtime etc/hosts etc/resolv.conf)
    for make_sandbox_file in ${make_sandbox_files[@]}
    do
        sudo umount -f ${make_sandbox_root}/${make_sandbox_file}
    done

    [[ -d ${make_sandbox_root} || -f ${make_sandbox_root} ]] && sudo rm -rf ${make_sandbox_root}
    sudo install -g ${make_sandbox_group} -o ${make_sandbox_user} -d -m a+rwx,o-w,g+s ${make_sandbox_root}/{etc,dev,usr/share/zoneinfo}
    sudo install -g ${make_sandbox_group} -o ${make_sandbox_user} -d -m a+rwx,g+s ${make_sandbox_root}/tmp
    for make_sandbox_file in ${make_sandbox_files[@]}
    do
        sudo -u ${make_sandbox_user} -g ${make_sandbox_group} touch ${make_sandbox_root}/${make_sandbox_file}
        sudo mount -o bind,ro,noexec /${make_sandbox_file} ${make_sandbox_root}/${make_sandbox_file}
    done
}

function configure_fpm_adm() {
    [[ -f /etc/php/${PHPVER}/fpm/example_pool.conf ]] && sudo cp -f /etc/php/${PHPVER}/fpm/example_pool.conf /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf
    sudo sed -i -e "s/\[www\]/[${PRJ_NAME}_adm]/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf

    sudo sed -i -e "s/user\s*=.*/user = ${USER_FPM_ADM}/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf
    sudo sed -i -e "s/group\s*=.*/group = ${GROUP_FPM_ADM}/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf

    sudo sed -i -e "s|listen\s*=.*|listen = ${SOCK_FPM_ADM}|g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf
    sudo sed -i -e "s/listen\.owner\s*=.*/listen.owner = ${USER_NGINX}/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf
    sudo sed -i -e "s/listen\.group\s*=.*/listen.group = ${GROUP_NGINX}/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf

    sudo sed -i -e "s|;access\.log\s*=.*|access.log = ${ACCESS_LOG_FPM_ADM}|g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf
    sudo sed -i -e "s/;access\.format\s*=/access.format =/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf

    install_user ${USER_FPM_ADM} ${GROUP_FPM_ADM}
    make_sandbox ${ROOT_FPM_ADM} ${USER_FPM_ADM} ${GROUP_FPM_ADM}
    sudo sed -i -e "s|;chroot\s*=.*|chroot = ${ROOT_FPM_ADM}|g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf

    sudo sed -i -e "s/;chdir\s*=\s*\/var\/www/chdir = $(escaped_htdocs_dir)/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf
    sudo sed -i -e "s/;clear_env\s*=\s*no/clear_env = no/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf
    sudo sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_adm.conf
}

function configure_fpm_prd() {
    [[ -f /etc/php/${PHPVER}/fpm/example_pool.conf ]] && sudo cp -f /etc/php/${PHPVER}/fpm/example_pool.conf /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf
    sudo sed -i -e "s/\[www\]/[${PRJ_NAME}_prd]/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf

    sudo sed -i -e "s/user\s*=.*/user = ${USER_FPM_PRD}/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf
    sudo sed -i -e "s/group\s*=.*/group = ${GROUP_FPM_PRD}/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf

    sudo sed -i -e "s|listen\s*=.*|listen = ${SOCK_FPM_PRD}|g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf
    sudo sed -i -e "s/listen\.owner\s*=.*/listen.owner = ${USER_NGINX}/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf
    sudo sed -i -e "s/listen\.group\s*=.*/listen.group = ${GROUP_NGINX}/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf

    sudo sed -i -e "s|;access\.log\s*=.*|access.log = ${ACCESS_LOG_PRD_PRD}|g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf
    sudo sed -i -e "s/;access\.format\s*=/access.format =/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf

    install_user ${USER_FPM_PRD} ${GROUP_FPM_PRD}
    sudo install -g ${GROUP_FPM_PRD} -o ${USER_FPM_PRD} -d -m a+rwx,o-w,g+s ${ROOT_FPM_PRD}
    sudo sed -i -e "s|;chroot\s*=.*|chroot = ${ROOT_FPM_PRD}|g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf

    sudo sed -i -e "s/;chdir\s*=\s*\/var\/www/chdir = $(escaped_htdocs_dir)/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf
    sudo sed -i -e "s/;clear_env\s*=\s*no/clear_env = no/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf
    sudo sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/${PHPVER}/fpm/pool.d/${PRJ_NAME}_prd.conf
}

function configure_nginx() {
    RESTRICTIONS=<<EOF
        location = /favicon.ico {
            #log_not_found off;
            #access_log off;
        }

        location = /robots.txt {
            allow all;
            try_files \$uri \$uri/ /index.php?\$args \@robots;
            #access_log off;
            #log_not_found off;
        }
        location @robots {
           return 200 "User-agent: *\\nDisallow: /wp-admin/\\nAllow: /wp-admin/admin-ajax.php\\n";
        }

        location ~ /\\.(ht|git|svn) {
            deny all;
        }
EOF

    cat << EOF | tee ${CONF_NGINX} > /dev/null
        user  ${USER_NGINX};
        group  ${GROUP_NGINX};
        worker_processes  1;
        error_log  /var/log/nginx/error.log warn;
        pid        /var/run/nginx.pid;

        events {
            worker_connections 1024;
        }

        http {
            include       /etc/nginx/mime.types;
            default_type  application/octet-stream;

            log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                              '$status $body_bytes_sent "$http_referer" '
                              '"$http_user_agent" "$http_x_forwarded_for"';
            access_log  /var/log/nginx/access.log  main;

            sendfile on;
            tcp_nopush on;
            tcp_nodelay on;
            keepalive_timeout 65;

            # types_hash_max_size 2048;
            # server_tokens off;
            # server_names_hash_bucket_size 64;
            # server_name_in_redirect off;

            ## SSL Settings
            ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
            ssl_prefer_server_ciphers on;

            ssl_certificate     ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_server.pem;
            ssl_certificate_key ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_server.key;
            ssl_trusted_certificate ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_ca.crt;
            ssl_client_certificate ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_client.pem;
            ssl_stapling on;
            ssl_verify_client optional;

            ## Gzip Settings
            # gzip on;

            # gzip_vary on;
            # gzip_proxied any;
            # gzip_comp_level 6;
            # gzip_buffers 16 8k;
            # gzip_http_version 1.1;
            # gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

            upstream wp_adm_upstream {
                server unix:${SOCK_FPM_ADM};
            }

            upstream wp_prd_upstream {
                server unix:${SOCK_FPM_PRD};
            }

            server {
                listen 80 default_server;
                listen [::]:80 default_server;
                listen 443 ssl default_server;
                listen [::]:443 ssl default_server;
                server_name ${PRJ_DOMAIN};

                root ${HTDOCS_DIR};
                index index.php;

                location @index_php_adm {
                    proxy_pass http://wp_adm_upstream;

                    proxy_set_header  Host \$host;

                    try_files \$uri =404;

                    proxy_set_header  DB_HOST "${DB_HOST_ADM}";
                    proxy_set_header  DB_PORT "${DB_PORT_ADM}";
                    proxy_set_header  DB_NAME "${DB_NAME_ADM}";
                    proxy_set_header  DB_USER "${DB_USER_ADM}";
                    proxy_set_header  DB_PASSWORD "${DB_PASSWORD_ADM}";

                    #fastcgi_pass unix:/run/php/php7.2-fpm.sock;
                    #include fastcgi_params;
                    #fastcgi_param  SCRIPT_FILENAME  \$realpath_root/\$fastcgi_script_name;
                    #fastcgi_index index.php;
                    #gzip on;
                    #gzip_comp_level 4;
                    #gzip_proxied any;
                }

                location @index_php_prd {
                    proxy_pass http://wp_prd_upstream;

                    proxy_set_header  Host \$host;

                    try_files \$uri =404;

                    proxy_set_header  DB_HOST "${DB_HOST_PRD}";
                    proxy_set_header  DB_PORT "${DB_PORT_PRD}";
                    proxy_set_header  DB_NAME "${DB_NAME_PRD}";
                    proxy_set_header  DB_USER "${DB_USER_PRD}";
                    proxy_set_header  DB_PASSWORD "${DB_PASSWORD_PRD}";

                    #fastcgi_pass unix:/run/php/php7.2-fpm.sock;
                    #include fastcgi_params;
                    #fastcgi_param  SCRIPT_FILENAME  \$realpath_root/\$fastcgi_script_name;
                    #fastcgi_index index.php;
                    #gzip on;
                    #gzip_comp_level 4;
                    #gzip_proxied any;
                }

                location / {
                    try_files \$uri \$uri/ @index_php_adm;
                }

                location ~* \\.(js|css|png|jpg|jpeg|gif|ico)$ {
                    expires max;
                    log_not_found off;
                }
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


# install_base
# purge_web
# install_web

# configure_openssh
# configure_hosts
setup_users_groups
setup_folders
# generate_cert

configure_fpm
configure_fpm_adm
configure_fpm_prd

#build_base_image
#build_image_nginx
#configure_nginx
#configure_unit
