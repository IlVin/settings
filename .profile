# export TERM=xterm-256color

case "$TERM" in
    "xterm") export TERM=xterm-256color;;
    "screen") export TERM=screen-256color;;
    "Eterm") export TERM=Eterm-256color;;
esac

if [[ $SSH_AUTH_SOCK && `readlink ~/.ssh/ssh_auth_sock` != $SSH_AUTH_SOCK ]]; then
    rm -f ~/.ssh/ssh_auth_sock
    ln -sf $SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock
#    export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
fi

export EDITOR=/usr/bin/vim

export MR_NET_TABLE=ipv6
export DEF_MR_SERVER=sakura.search.yandex.net:8013
export MR_USER=tmp

alias valgrind='/home/ilvin/local/bin/valgrind'

#export CXX=/usr/bin/clang++
#export CC=/usr/bin/clang

# Alias for ssh-agent hosts
#alias ssh='eval $(/usr/bin/keychain --eval --agents ssh -Q --quiet ~/.ssh/id_ecdsa) && ssh'

export LANGUAGE=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_NUMERIC=en_US.UTF-8
export LC_TIME=en_US.UTF-8
export LC_COLLATE=en_US.UTF-8
export LC_MONETARY=en_US.UTF-8
export LC_MESSAGES=en_US.UTF-8
export LC_PAPER=en_US.UTF-8
export LC_NAME=en_US.UTF-8
export LC_ADDRESS=en_US.UTF-8
export LC_TELEPHONE=en_US.UTF-8
export LC_MEASUREMENT=en_US.UTF-8
export LC_IDENTIFICATION=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ESP8266 FreeRTOS toolchain
# https://github.com/espressif/ESP8266_RTOS_SDK
export IDF_PATH=~/esp/ESP8266_RTOS_SDK
export PATH=~/esp/xtensa-lx106-elf/bin:$PATH

# xubuntu самостоятельно менеджерит ssh-agent
#eval $(ssh-agent)
