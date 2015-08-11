if [[ $SSH_AUTH_SOCK && `readlink ~/.ssh/ssh_auth_sock` != $SSH_AUTH_SOCK ]]; then
    rm -f ~/.ssh/ssh_auth_sock
    ln -sf $SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock
#    export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
fi

export MR_NET_TABLE=ipv6
export DEF_MR_SERVER=cedar00.search.yandex.net:8013
export MR_USER=tmp
