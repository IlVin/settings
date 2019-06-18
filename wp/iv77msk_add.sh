#/bin/sh

##############################################################################################
# ВНИМАНИЕ! Запуск этого скрипта означает принятие договора-аферты, расположенного на сайте: #
# https://iv77msk.ru/offer.html                                                              #
# ############################################################################################

SERVICE_USER='iv77msk_ru'

set +x

alias sudo='sudo -S'

# Установить bash
sudo apt-get update -yqq
sudo apt-get install -yqq bash openssh openssh-server rand

# Проверяем существование пользователя
user_id=$(id -u ${SERVICE_USER} 2>/dev/null)
if ! [ "${user_id}" = "" ]
then
    SERVICE_HOME=$(grep ${SERVICE_USER} /etc/passwd | cut -d ':' -f 6)
    echo "\nUser ${SERVICE_USER} already exists. Remove it:"
    echo "\$ sudo userdel ${SERVICE_USER} && sudo rm -rf ${SERVICE_HOME}"
    echo "And run this script a second time.\n"
    exit 1
fi

# Проверяем существование группы пользователя
group_id=$(getent group ${SERVICE_USER})
if [ "${group_id}" = "" ]
then
    sudo groupadd ${SERVICE_USER}
fi

# Добавить пользователя с правами sudo
sudo useradd \
    -m \
    -c "Service account of iv77msk.ru" \
    -g ${SERVICE_USER} \
    -G sudo \
    -s /bin/bash \
    ${SERVICE_USER};

SERVICE_HOME=$(grep ${SERVICE_USER} /etc/passwd | cut -d ':' -f 6)

# Сделать пользователю беспарольный sudo
echo ${SERVICE_USER}\ ALL=\(ALL\)\ NOPASSWD:\ ALL | sudo tee /etc/sudoers.d/${SERVICE_USER} > /dev/null \
&& sudo chmod 0440 /etc/sudoers.d/${SERVICE_USER};

# Настроить пользователю SSH
sudo mkdir -p ${SERVICE_HOME}/.ssh
sudo chown ${SERVICE_USER}:${SERVICE_USER} ${SERVICE_HOME}/.ssh
sudo chmod a-rwx,u+rwx ${SERVICE_HOME}/.ssh

[ -f ${SERVICE_HOME}/.ssh/authorized_keys ] && sed -i -r "/${SERVICE_USER}@IlVin/d" ${SERVICE_HOME}/.ssh/authorized_keys

cat << EOF | sudo tee -a ${SERVICE_HOME}/.ssh/authorized_keys > /dev/null
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtTiHgVLPVD4xN24NYfeAupqO/EC0rqKCi7IsHG8qdozcAEF0K7KTLEiFJXJ40mnTlKHrw3c1mhxYutkzOKaVtwIVnXcr0C9cHNMYl/Du7Z5lef2aR+30Ka6dGQ93mVHwgwm8lERwpolzylLCJQe8j+RD5/6rY7/+Aeo9dfvlnjyGKP9jte71cidaj3/e/dCtcSf3SQV+JnXk0otPgKZ+qQQHbqpJAX8GdlTRy2DECYVcMHDww2NERcAeKeS8E4rb+cIkMO7mJico92RAVkihNzeBESRtqfcSwDIWB30PzoRRgRAansEdPSRB1FC8GUZhYq7/d6r6DmbwDlZPLNu3d ${SERVICE_USER}@IlVin
EOF

sudo chown ${SERVICE_USER}:${SERVICE_USER} ${SERVICE_HOME}/.ssh/authorized_keys
sudo chmod a-rwx,u+rw ${SERVICE_HOME}/.ssh/authorized_keys

# SSH Agent setup
sudo sed -i -r \
    -e 's/#?\s*(PubkeyAuthentication)\s+(yes|no)/\1 yes/g' \
    -e 's/#?\s*(RSAAuthentication)\s+(yes|no)/\1 yes/g' \
    -e 's/#?\s*(PasswordAuthentication)\s+(yes|no)/\1 no/g' \
    -e 's/#?\s*(AllowAgentForwarding)\s+(yes|no)/\1 yes/g' \
    -e 's/#?\s*(X11Forwarding)\s+(yes|no)/\1 yes/g' \
    -e 's/#?\s*(UsePAM)\s+(yes|no)/\1 yes/g' \
    -e 's/#?\s*(UseLogin)\s+(yes|no)/\1 no/g' \
    -e 's/#?\s*(TCPKeepAlive)\s+(yes|no)/\1 yes/g' \
/etc/ssh/sshd_config
sudo service sshd restart

# Добавить пользователю хостов в список известных
for SERVICE_HOST in ca.iv77msk.ru iv77msk.ru
do
    [ -f ${SERVICE_HOME}/.ssh/known_hosts ] && sudo ssh-keygen -R ${SERVICE_HOST} -f ${SERVICE_HOME}/.ssh/known_hosts
    ssh-keyscan ${SERVICE_HOST} 2>/dev/null | sudo tee -a ${SERVICE_HOME}/.ssh/known_hosts > /dev/null
    sudo chown ${SERVICE_USER}:${SERVICE_USER} ${SERVICE_HOME}/.ssh/known_hosts
    sudo chmod a-rwx,u+rw ${SERVICE_HOME}/.ssh/known_hosts
done

cat << EOF

ПОЗДРАВЛЯЕМ!

В OS добавлен сервисный root пользователь ${SERVICE_USER},
с помощью которого сервис https://iv77msk.ru/ производит
системную настройку ПО.

ВНИМАНИЕ: На хосте отключен вход с помощью логин/пароля.
Пользуйтесь входом в OS с помощью SSH ключа.

Для удаления пользователя ${SERVICE_USER} нужно выполнить команды:

sudo userdel ${SERVICE_USER}
sudo rm -rf ${SERVICE_HOME}
sudo rm -f /etc/sudoers.d/${SERVICE_USER}

ВНИМАНИЕ: Удалив пользователя ${SERVICE_USER},
вы отказываетесь от поддержки со стороны https://iv77msk.ru/


EOF

