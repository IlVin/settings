#/sbin/bash

##############################################################################################
# ВНИМАНИЕ! Запуск этого скрипта означает принятие договора-аферты, расположенного на сайте: #
# https://iv77msk.ru/offer.html                                                              #
# ############################################################################################

SERVICE_USER='iv77msk_ru'

set -x

alias sudo='sudo -S'

# Установить bash
sudo apt-get update -yqq
sudo apt-get install -yqq bash

# Проверяем существование пользователя
if [[ $(id -u ${SERVICE_USER} 2>/dev/null) != '' ]]
then
    echo -e "\nUser ${SERVICE_USER} already exists. Remove it:\n\$ sudo userdel ${SERVICE_USER}\nAnd run this script a second time.\n"
    exit 1
    SERVICE_HOME=$(grep ${SERVICE_USER} /etc/passwd | cut -d ':' -f 6)
    sudo userdel ${SERVICE_USER}
    [[ -d ${SERVICE_HOME} ]] && sudo rm -rf ${SERVICE_HOME}
fi

# Проверяем существование группы пользователя
if [[ $(getent group ${SERVICE_USER}) == '' ]]
then
    sudo groupadd ${SERVICE_USER}
fi

# Добавить пользователя с правами sudo
sudo useradd \
    -m \
    -c "Service account of iv77msk.ru" \
    -g ${SERVICE_USER} \
    -G sudo \
    -s /sbin/bash \
    ${SERVICE_USER};

SERVICE_HOME=$(grep ${SERVICE_USER} /etc/passwd | cut -d ':' -f 6)

# Сделать пользователю безпарольный sudo
echo ${SERVICE_USER}\ ALL=\(ALL\)\ NOPASSWD:\ ALL | sudo tee /etc/sudoers.d/${SERVICE_USER} > /dev/null \
&& sudo chmod 0440 /etc/sudoers.d/${SERVICE_USER};

# Настроить пользователю SSH
sudo mkdir -p ${SERVICE_HOME}/.ssh
sudo chown ${SERVICE_USER}:${SERVICE_USER} ${SERVICE_HOME}/.ssh
sudo chmod a-rwx,u+rwx ${SERVICE_HOME}/.ssh
if [[ !(-f ${SERVICE_HOME}/.ssh/authorized_keys) || ($(grep "rsa-key-${SERVICE_USER}-20150714" ${SERVICE_HOME}/.ssh/authorized_keys | wc -l) == 0) ]]
then
    cat << EOF | sudo tee -a ${SERVICE_HOME}/.ssh/authorized_keys > /dev/null
ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAmiXomW7qcG3PJqhJeNs+NmmNrwN3lrBwx2hR55vS+Q5l5MR5eUdjB94ou+ag69PtVPuslVhJ8cNY4IaNeWog5T9ulSs9vSb9+7pnEws34Vy5Bu0ePE+HXGZ8EHnND4C1ljsbM49n35BxRtrjOeEkFWeNNaKqPqvwutebrg0Bu+LQLZ69xBV0dBpfDZwrsTkDePQKV9E6b26fi+tAmZEVbInT4wHyXXSDmlRlv86oF3WFpyLxKNsZsTcmJMt1Gz5kzJr4fGcAp+kE5Nzhg+E/+QOAKa/b2KPm16jMMUuazI8b6wyTwXKB7WI516gr1DJSlMqKiNQALQQJQv59q/u0jw== rsa-key-${SERVICE_USER}-20150714
EOF
fi
sudo chown ${SERVICE_USER}:${SERVICE_USER} ${SERVICE_HOME}/.ssh/authorized_keys
sudo chmod a-rwx,u+rw ${SERVICE_HOME}/.ssh/authorized_keys

# Добавить пользователю хостов в список известных
for SERVICE_HOST in ca.iv77msk.ru iv77msk.ru
do
    [[ -f ${SERVICE_HOME}/.ssh/known_hosts ]] && sudo ssh-keygen -R ${SERVICE_HOST} -f ${SERVICE_HOME}/.ssh/known_hosts
    ssh-keyscan ${SERVICE_HOST} 2>/dev/null | sudo tee -a ${SERVICE_HOME}/.ssh/known_hosts > /dev/null
    sudo chown ${SERVICE_USER}:${SERVICE_USER} ${SERVICE_HOME}/.ssh/known_hosts
    sudo chmod a-rwx,u+rw ${SERVICE_HOME}/.ssh/known_hosts
done

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

cat << EOF

ПОЗДРАВЛЯЕМ!

В OS добавлен сервисный пользователь ${SERVICE_USER},
с помощью которого сервис https://iv77msk.ru/
производит системную настройку ПО с правами root.
Для удаления этого пользователя нужно выполнить команды:

sudo userdel ${SERVICE_USER}
sudo rm -rf ${SERVICE_HOME}
sudo rm -f /etc/sudoers.d/${SERVICE_USER}

ВНИМАНИЕ: Удалив пользователя ${SERVICE_USER},
вы отказываетесь от поддержки со стороны https://iv77msk.ru/


EOF

