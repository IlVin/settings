#!/bin/bash -x

set +x

WP_USER='ilvin'
WP_HOST='192.168.1.42'

SERVICE_USER='iv77msk_ru'
SERVICE_HOME=$(grep ${SERVICE_USER} /etc/passwd | cut -d ':' -f 6)

## Подсоединяемся к удаленному хосту sudo юзером и устанавливаем сервисного пользователя
#echo "ENTER PASSWORD FOR ${WP_USER}:"
#read PASSWD
#ssh ${WP_USER}@${WP_HOST} "echo '${PASSWD}' | sudo -Sv && /bin/sh -s" -- < ./iv77msk_add.sh --arguments

# Запускаем скрипт установки из под сервисного пользователя
cat ./set_env.sh ./configure.sh | ssh ${SERVICE_USER}@${WP_HOST} 'bash -s'

#SUDO_WRAPPER=$(cat << EOF
#(echo ${PASSWD} | sudo -S echo ilvin  ALL=\\(ALL\\) NOPASSWD: ALL | sudo -S tee /etc/sudoers.d/ilvin) \
#&& (echo ${PASSWD} | sudo -S chmod 0440 /etc/sudoers.d/ilvin);
#EOF
#)
#
#(echo "${SUDO_WRAPPER}" && cat ./set_env.sh ./configure.sh) \
#| ssh ilvin@wp 'bash -s'


