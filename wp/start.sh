#!/bin/bash -x

set -x

echo "ENTER PASSWORD FOR sudo:"
read PASSWD

SUDO_WRAPPER=$(cat << EOF
(echo ${PASSWD} | sudo -S echo ilvin  ALL=\\(ALL\\) NOPASSWD: ALL | sudo -S tee /etc/sudoers.d/ilvin) \
&& (echo ${PASSWD} | sudo -S chmod 0440 /etc/sudoers.d/ilvin);
EOF
)

(echo "${SUDO_WRAPPER}" && cat ./set_env.sh ./configure.sh) \
| ssh ilvin@wp 'bash -s'


#ssh ADDRESS 'echo "rootpass" | sudo -Sv && bash -s' -- < BASH_FILE --arguments
