
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
    curl 'https://nginx.org/keys/nginx_signing.key' > ~/nginx_signing.key
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
