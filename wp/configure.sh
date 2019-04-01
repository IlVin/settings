#!/bin/sh

# OpenSSH
[ -d ~/.ssh ] || mkdir ~/.ssh
[ -d ~/.ssh ] && chmod 700 ~/.ssh

DB_NAME="wp_hosting"
DB_USER=${USER}
DB_PASSWORD="P@ssw0rd"
DB_HOST="localhost"

NGINX_USER="nginx"
PHP_USER="php"
FS_USER=${USER}

GROUP="www-data"

########################
#    DNS               #
########################

SITENAME="wp.iv77msk.ru"
sudo sed --in-place "s/127\.0\.0\.1\s+${SITENAME}//g" /etc/hosts
echo "127.0.0.1 ${SITENAME}" | sudo tee -a /etc/hosts > /dev/null


########################
#    GROUPS            #
########################

if [ `getent group ${GROUP}` ]
then
    echo "Group ${GROUP} exists"
else
    sudo groupadd ${GROUP}
fi

for OWNER in ${FS_USER} ${NGINX_USER} ${PHP_USER}
do
    sudo usermod -a -G ${GROUP} ${OWNER}
done

########################
#    FOLDERS           #
########################

PROJECT_DIR="/www/${SITENAME}"
HTDOCS_DIR="${PROJECT_DIR}/htdocs"
WP_DIR="${HTDOCS_DIR}"
LOG_DIR="${PROJECT_DIR}/logs"
DB_DIR="${PROJECT_DIR}/mysql"
SOFT_DIR="${PROJECT_DIR}/soft"
CONF_DIR="${PROJECT_DIR}/conf"

[ -d ${HTDOCS_DIR} ] && rm -rf ${HTDOCS_DIR}/*
for DIR in ${PROJECT_DIR} ${HTDOCS_DIR} ${LOG_DIR} ${DB_DIR} ${SOFT_DIR} ${WP_DIR} ${CONF_DIR}
do
    sudo install -g ${GROUP} -o ${FS_USER} -d -m a+rwx,o-w,g+s ${DIR}
done

#echo "<?php phpinfo();?>" > ${HTDOCS_DIR}/index.php

########################
#    PHP               #
########################

sudo sed -i 's/^;cgi\.fix_pathinfo=1/cgi\.fix_pathinfo=0/g' /etc/php/7.2/fpm/php.ini
sudo sed -i "s/^user = www-data/user = ${PHP_USER}/g" /etc/php/7.2/fpm/pool.d/www.conf
sudo sed -i "s/^group = www-data/group = ${GROUP}/g" /etc/php/7.2/fpm/pool.d/www.conf

sudo sed -i "s/^listen.owner = www-data/listen.owner = ${PHP_USER}/g" /etc/php/7.2/fpm/pool.d/www.conf
sudo sed -i "s/^listen.group = www-data/listen.group = ${GROUP}/g" /etc/php/7.2/fpm/pool.d/www.conf


########################
#    Nginx             #
########################
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

cat << EOF | sudo tee ${CONF_DIR}/${SITENAME}.conf > /dev/null
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${SITENAME};

    root ${HTDOCS_DIR};
    index index.php;

    ${RESTRICTIONS}

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
        fastcgi_param  DB_NAME "${DB_NAME}";
        fastcgi_param  DB_USER "${DB_USER}";
        fastcgi_param  DB_PASSWORD "${DB_PASSWORD}";
        fastcgi_param  DB_HOST "${DB_HOST}";
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
sudo ln -sf ${CONF_DIR}/${SITENAME}.conf /etc/nginx/conf.d/${SITENAME}.conf
sudo service nginx restart




########################
#    mariadb           #
########################
sudo mysql_secure_installation
sudo mysql -uroot -p${DB_PASSWORD} << EOF
SHOW DATABASES;
DROP DATABASE IF EXISTS \`${DB_NAME}\`;
CREATE DATABASE \`${DB_NAME}\`;
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO ${DB_USER}@'${DB_HOST}' IDENTIFIED BY '${DB_PASSWORD}';
FLUSH PRIVILEGES;
EOF



########################
#    WordPress         #
########################
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


sudo service nginx restart
sudo service php7.2-fpm restart