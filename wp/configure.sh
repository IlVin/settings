#!/bin/bash +x

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
}

function setup_folders() {
    for DIR in ${PRJ_ROOT} ${CONF_DIR} ${HTDOCS_DIR} ${WP_DIR} ${LOG_DIR} ${DB_DIR} ${SOFT_DIR} ${CACHE_DIR} ${PID_DIR} ${CERT_DIR}
    do
        sudo install -g ${PRJ_GROUP} -o ${PRJ_OWNER} -d -m a+rwx,o-w,g+s ${DIR}
    done
}

function generate_cert() {
    # Приватный ключ центра сертификации
    openssl genrsa -out ${CERT_DIR}/ca.key 4096

    # Самоподписанный сертификат
    openssl req -new -sha256 -x509 -days 10950 -key ${CERT_DIR}/ca.key -out ${CERT_DIR}/ca.crt

    # Приватный ключ web-сервера
    openssl genrsa -out ${CERT_DIR}/server.key 4096

    # Сертификат для WEB-сервера
    openssl req -new -key ${CERT_DIR}/server.key -sha256 -out ${CERT_DIR}/server.csr

    # Подписываем сертификат WEB-сервера нашим центром сертификации
    openssl x509 -req -days 10950 -in ${CERT_DIR}/server.csr -CA ${CERT_DIR}/ca.crt -CAkey ${CERT_DIR}/ca.key -set_serial 0x`openssl rand -hex 16` -sha256 -out ${CERT_DIR}/server.pem

    # клиентский приватный ключ
    openssl genrsa -out ${CERT_DIR}/client.key 4096

    # клиентский сертификат
    openssl req -new -key ${CERT_DIR}/client.key -sha256 -out ${CERT_DIR}/client.csr

    # Подписываем клиентский сертификат нашим центром сертификации.
    openssl x509 -req -days 10950 -in ${CERT_DIR}/client.csr -CA ${CERT_DIR}/ca.crt -CAkey ${CERT_DIR}/ca.key -set_serial 0x`openssl rand -hex 16` -sha256 -out ${CERT_DIR}/client.pem

    #  Создание сертфиката в формате PKCS#12 для браузеров
    openssl pkcs12 -export -in ${CERT_DIR}/client.pem -inkey ${CERT_DIR}/client.key -name "Sub-domain certificate for ${PRJ_DOMAIN}" -out ${CERT_DIR}/client.p12
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

    cat << EOF | sudo tee ${CONF_DIR}/nginx.conf > /dev/null
        server {
            listen 80 default_server;
            listen [::]:80 default_server;
            server_name ${PRJ_DOMAIN};

            root ${HTDOCS_DIR};
            index index.php;

            location / {
                try_files \$uri \$uri/ /index.php?\$args ;
            }

            location ~* \\.php$ {
                        #NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
                try_files \$uri =404;
                include fastcgi_params;
                fastcgi_param  SCRIPT_FILENAME  \$realpath_root/\$fastcgi_script_name;
                fastcgi_index index.php;
                fastcgi_pass unix:/run/php/php7.2-fpm.sock;
                fastcgi_param  DB_NAME "${DB_PROD_NAME}";
                fastcgi_param  DB_USER "${DB_PROD_USER}";
                fastcgi_param  DB_PASSWORD "${DB_PROD_PASSWORD}";
                fastcgi_param  DB_HOST "${DB_PROD_HOST}";
                #gzip on;
                #gzip_comp_level 4;
                #gzip_proxied any;
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

configure_openssh
configure_hosts
setup_users_groups
setup_folders
generate_cert
configure_nginx
