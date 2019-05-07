#!/bin/bash -x

. ./set_env.sh

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
}

function setup_folders() {
    for VAR in PRJ_ROOT CONF_DIR IMG_DIR HTDOCS_DIR WP_DIR DB_DIR SOFT_DIR CACHE_DIR CERT_DIR RUN_DIR LOG_DIR STATE_DIR
    do
        sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${!VAR}
        for SUFFIX in NGINX UNIT_ADM UNIT_PRD BASE FPM FPM_ADM FPM_PRD
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



# https://habr.com/ru/post/316802/
function build_image_fpm_adm() {
    cat << EOF > ${IMG_DIR_FPM_ADM}/install.sh
#!/bin/bash -x

    sudo sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/${PHPVER}/fpm/php-fpm.conf

    sudo sed -i -e "s/listen\s*=.*/listen = 9000/g" /etc/php/${PHPVER}/fpm/pool.d/www.conf
    sudo sed -i "s|;\s*log_errors|log_errors On|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i -e "s/;chdir\s*=\s*\/var\/www/chdir = $(escaped_htdocs_dir)/g" /etc/php/${PHPVER}/fpm/pool.d/www.conf
    sudo sed -i -e "s/user\s*=\s*nobody/user = ${USER_ADM}/g" /etc/php/${PHPVER}/fpm/pool.d/www.conf
    sudo sed -i -e "s/group\s*=\s*nobody/group = ${GROUP_ADM}/g" /etc/php/${PHPVER}/fpm/pool.d/www.conf
    sudo sed -i -e "s/;clear_env\s*=\s*no/clear_env = no/g" /etc/php/${PHPVER}/fpm/pool.d/www.conf
    sudo sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/${PHPVER}/fpm/pool.d/www.conf

    sudo sed -i "s/display_errors\s*=\s*(On|Off)/display_errors = On/" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/display_startup_errors\s*=\s*(On|Off)/display_startup_errors = On/" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/log_errors\s*=\s*(On|Off)/log_errors = On/" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|doc_root\s*=.*|doc_root = ${HTDOCS_DIR}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/user_dir\s*=.*/user_dir =/" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/allow_url_fopen\s*=\s*(On|Off)/allow_url_fopen = Off/" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/allow_url_include\s*=\s*(On|Off)/allow_url_include = Off/" /etc/php/${PHPVER}/fpm/php.ini


    sudo sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|post_max_size =.*|post_max_size = ${PHP_MAX_POST}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/${PHPVER}/fpm/php.ini

EOF
    chmod a+x ${IMG_DIR_FPM_ADM}/install.sh

cat << EOF > ${IMG_DIR_FPM_ADM}/Dockerfile
    FROM ${IMG_NAME_BASE}
    MAINTAINER Ilia Vinokurov <ilvin@iv77msk.ru>
    ADD ./ /container
    ENV DEBIAN_FRONTEND noninteractive
    RUN /container/install.sh
    EXPOSE 9000
    CMD ["php-fpm${PHPVER}"]
EOF

    RETPATH=$(pwd)
    cd ${IMG_DIR_FPM_ADM} && sudo docker build -t ${IMG_NAME_FPM_ADM} ./
    cd ${RETPATH}
    sudo docker image ls
}

function build_image_fpm_prd() {
    cat << EOF > ${IMG_DIR_FPM_PRD}/install.sh
#!/bin/bash -x

    sudo sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/${PHPVER}/fpm/php-fpm.conf

    sudo sed -i -e "s/listen\s*=.*/listen = 9000/g" /etc/php/${PHPVER}/fpm/pool.d/www.conf
    sudo sed -i -e "s/;chdir\s*=\s*\/var\/www/chdir = $(escaped_htdocs_dir)/g" /etc/php/${PHPVER}/fpm/pool.d/www.conf
    sudo sed -i -e "s/user\s*=\s*nobody/user = ${USER_PRD}/g" /etc/php/${PHPVER}/fpm/pool.d/www.conf
    sudo sed -i -e "s/group\s*=\s*nobody/group = ${GROUP_PRD}/g" /etc/php/${PHPVER}/fpm/pool.d/www.conf
    sudo sed -i -e "s/;clear_env\s*=\s*no/clear_env = no/g" /etc/php/${PHPVER}/fpm/pool.d/www.conf
    sudo sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/${PHPVER}/fpm/pool.d/www.conf

    sudo sed -i "s/display_errors\s*=\s*(On|Off)/display_errors = Off/" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/display_startup_errors\s*=\s*(On|Off)/display_startup_errors = Off/" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/log_errors\s*=\s*(On|Off)/log_errors = On/" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s|post_max_size =.*|post_max_size = ${PHP_MAX_POST}|" /etc/php/${PHPVER}/fpm/php.ini
    sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/${PHPVER}/fpm/php.ini

EOF
    chmod a+x ${IMG_DIR_FPM_PRD}/install.sh

cat << EOF > ${IMG_DIR_FPM_PRD}/Dockerfile
    FROM ${IMG_NAME_BASE}
    MAINTAINER Ilia Vinokurov <ilvin@iv77msk.ru>
    ADD ./ /container
    ENV DEBIAN_FRONTEND noninteractive
    RUN /container/install.sh
    EXPOSE 9000
    CMD ["php-fpm${PHPVER}"]
EOF

    RETPATH=$(pwd)
    cd ${IMG_DIR_FPM_PRD} && sudo docker build -t ${IMG_NAME_FPM_PRD} ./
    cd ${RETPATH}
    sudo docker image ls
}

function configure_docker_nets() {
    for NET_ID in $(net_adm_ids) $(net_prd_ids)
    do
        sudo docker network inspect ${NET_ID} | jq '.[].Containers | keys' | grep -Po '"[^"]+"' | grep -Po '[^"]+' | xargs -r sudo docker container stop
        sudo docker network rm ${NET_ID}
    done
    sudo docker network create "${NET_ADM}" --internal --attachable
    sudo docker network create "${NET_PRD}" --internal --attachable
}

function configure_unit() {
    cat << EOF | jq . | tee ${CONF_UNIT_ADM} > /dev/null
    {
        "listeners": {
            "*:${PORT_UNIT_ADM}": {
                "application": "WP_INDEX_ADM"
             }
        },

        "applications": {
            "WP_INDEX_ADM": {
                "type": "php",
                "processes": {
                    "max": 20,
                    "spare": 5
                },
                "user": "${PRJ_OWNER}",
                "group": "${PRJ_GROUP}",
                "root": "${HTDOCS_DIR}",
                "script": "index.php"
            }
        }
    }
EOF
    cat << EOF | jq . | tee ${CONF_UNIT_PRD} > /dev/null
    {
        "listeners": {
            "*:${PORT_UNIT_PRD}": {
                "application": "WP_INDEX_PRD"
             }
        },

        "applications": {
            "WP_INDEX_PRD": {
                "type": "php",
                "processes": {
                    "max": 20,
                    "spare": 5
                },
                "user": "${PRJ_OWNER}",
                "group": "${PRJ_GROUP}",
                "root": "${HTDOCS_DIR}",
                "script": "index.php"
            }
        }
    }
EOF
}

function configure_nginx() {
    RESTRICTIONS=<<EOF
        # Global restrictions configuration file.
        # Designed to be included in any server {} block.
        location = /favicon.ico {
            log_not_found off;
            access_log off;
        }

        # robots.txt fallback to index.php
        location = /robots.txt {
            # Some WordPress plugin gererate robots.txt file
            allow all;
            try_files \$uri \$uri/ /index.php?\$args \@robots;
            access_log off;
            log_not_found off;
        }

        # additional fallback if robots.txt doesn't exist
        location @robots {
           return 200 "User-agent: *\\nDisallow: /wp-admin/\\nAllow: /wp-admin/admin-ajax.php\\n";
        }

        # Deny all attempts to access hidden files such as .htaccess, .htpasswd, .DS_Store (Mac) excepted .well-known directory.
        # Keep logging the requests to parse later (or to pass to firewall utilities such as fail2ban)
        location ~ /\\.(?!well-known\\/) {
            deny all;
        }

        # Deny access to any files with a .php extension in the uploads directory for the single site
        location /wp-content/uploads {
            location ~ \\.php$ {
            deny all;
            }
        }

        # Deny access to any files with a .php extension in the uploads directory
        # Works in sub-directory installs and also in multisite network
        # Keep logging the requests to parse later (or to pass to firewall utilities such as fail2ban)
        location ~* /(?:uploads|files)/.*\\.php$ {
            deny all;
        }

        location ~ /\\.(ht|git|svn) {
            deny all;
        }
EOF

    cat << EOF | tee ${CONF_NGINX} > /dev/null
        events {
            worker_connections 768;
            # multi_accept on;
        }

        http {
            sendfile on;
            tcp_nopush on;
            tcp_nodelay on;
            keepalive_timeout 65;
            types_hash_max_size 2048;
            # server_tokens off;

            # server_names_hash_bucket_size 64;
            # server_name_in_redirect off;

            include /etc/nginx/mime.types;
            default_type application/octet-stream;

            ## SSL Settings
            ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
            ssl_prefer_server_ciphers on;

            ssl_certificate     ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_server.pem;
            ssl_certificate_key ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_server.key;
            ssl_trusted_certificate ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_ca.crt;
            ssl_client_certificate ${CERT_DIR_NGINX}/${PRJ_DOMAIN}_client.pem;
            ssl_stapling on;
            ssl_verify_client optional;

            ## Logging Settings
            access_log /var/log/nginx/access.log;
            error_log /var/log/nginx/error.log;

            ## Gzip Settings
            # gzip on;

            # gzip_vary on;
            # gzip_proxied any;
            # gzip_comp_level 6;
            # gzip_buffers 16 8k;
            # gzip_http_version 1.1;
            # gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

            upstream wp_adm_upstream {
                server ${HOSTNAME_UNIT_ADM}:${PORT_UNIT_ADM};
            }

            upstream wp_prd_upstream {
                server ${HOSTNAME_UNIT_PRD}:${PORT_UNIT_PRD};
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

configure_openssh
configure_hosts
setup_users_groups
setup_folders
generate_cert
build_base_image
build_image_nginx
build_image_fpm_adm
build_image_fpm_prd
#configure_docker_nets
#configure_nginx
#configure_unit
