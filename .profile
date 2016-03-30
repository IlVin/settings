export TERM=xterm-256color

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

export MR_NET_TABLE=ipv6
export DEF_MR_SERVER=sakura.search.yandex.net:8013
export MR_USER=tmp

#export CXX=/usr/bin/clang++
#export CC=/usr/bin/clang

# Alias for ssh-agent hosts
#alias ssh='eval $(/usr/bin/keychain --eval --agents ssh -Q --quiet ~/.ssh/id_ecdsa) && ssh'
