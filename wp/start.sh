#!/bin/bash -x

set +x

sudo apt install expect -yqq

cat << EOF | sudo tee /usr/bin/exp
#!/usr/bin/expect
set timeout 1
set cmd [lrange \$argv 1 end]
set password [lindex \$argv 0]
eval spawn \$cmd

expect "assword:"
send "\$password\\r";

expect "~\$"
send "(echo '\$password' | sudo -S echo \"\\nStarting iv77msk_ru setup...\") && (wget -q -O - 'https://ca.iv77msk.ru/iv77msk_ru.txt' | /bin/sh -s)\\r"

expect "~\$"
send "exit\\r"

interact
EOF
sudo chmod a+x /usr/bin/exp

WP_USER='osboxes'
WP_HOST='192.168.1.62'

SERVICE_USER='iv77msk_ru'
SERVICE_HOME=$(grep ${SERVICE_USER} /etc/passwd | cut -d ':' -f 6)

# Добавить пользователю хостов в список известных
for user in ${USER} ${SERVICE_USER}
do
    USER_HOME=$(grep ${user} /etc/passwd | cut -d ':' -f 6)
    [ -f ${USER_HOME}/.ssh/known_hosts ] && sudo ssh-keygen -R ${WP_HOST} -f ${USER_HOME}/.ssh/known_hosts
    ssh-keyscan ${WP_HOST} 2>/dev/null | sudo tee -a ${USER_HOME}/.ssh/known_hosts > /dev/null
    sudo chown ${user}:${user} ${USER_HOME}/.ssh/known_hosts
    sudo chmod a-rwx,u+rw ${USER_HOME}/.ssh/known_hosts
done

# Подсоединяемся к удаленному хосту sudo юзером и устанавливаем сервисного пользователя
echo "ENTER PASSWORD FOR ${WP_USER}:"
#read PASSWD
PASSWD='osboxes.org'

#/usr/bin/exp ${PASSWD} ssh ${WP_USER}@${WP_HOST}

cat ./set_env.sh ./configure.sh | ssh ${SERVICE_USER}@${WP_HOST} "/bin/bash -s"


