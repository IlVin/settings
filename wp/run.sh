#!/bin/bash -x

if [[ ${SET_ENV} != 'INCLUDED' ]]
then
    . ./set_env.sh
fi

umask ${UMASK}

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

