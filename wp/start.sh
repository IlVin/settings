#!/bin/bash -x

set -x

## Подсоединяемся к удаленному хосту sudo юзером и устанавливаем сервисного пользователя
#echo "ENTER PASSWORD FOR sudo:"
#read PASSWD
#ssh ilvin@wp "echo '${PASSWD}' | sudo -Sv && bash -s" -- < ./iv77msk_add.sh --arguments

# Запускаем скрипт установки из под сервисного пользователя
cat ./set_env.sh ./configure.sh | ssh -A iv77msk_ru@wp 'bash -s'

#SUDO_WRAPPER=$(cat << EOF
#(echo ${PASSWD} | sudo -S echo ilvin  ALL=\\(ALL\\) NOPASSWD: ALL | sudo -S tee /etc/sudoers.d/ilvin) \
#&& (echo ${PASSWD} | sudo -S chmod 0440 /etc/sudoers.d/ilvin);
#EOF
#)
#
#(echo "${SUDO_WRAPPER}" && cat ./set_env.sh ./configure.sh) \
#| ssh ilvin@wp 'bash -s'


