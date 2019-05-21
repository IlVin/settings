#!/bin/bash -x

. ./set_env.sh

function start_nginx() {
    sudo service nginx start
    sudo systemctl status nginx.service
}

function stop_nginx() {
    sudo service nginx stop
}

function start_fpm() {
    sudo service php7.2-fpm start
    sudo systemctl status php7.2-fpm.service
}

function stop_fpm() {
    sudo service php7.2-fpm stop
}

function show_help() {
    echo "Unknown argument"
}

while (( $# ))
do
    case "${1,,}" in
        stop) stop_nginx && stop_fpm;;
        nginx) stop_nginx && start_nginx;;
        fpm) stop_fpm && start_fpm;;
        *) show_help;;
    esac
    shift
done

