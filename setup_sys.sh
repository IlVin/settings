#!/bin/bash

    sudo apt-get update
    sudo apt-get install \
        dconf-tools \
        nmap \
        bash \
        gv \
        pv \
        parallel \
        liblz4-tool \
        curl \
        htop \
        sysstat \
        vim \
        vim-gtk3 \
        font-manager \
        subversion \
        git-svn \
        keychain \
        tmux \
        mc \


    sudo locale-gen en_US.UTF-8 ru_RU.UTF-8
#    sudo update-locale LANG=ru_RU.UTF-8 LANGUAGE=ru_RU:ru:en_US:en
    sudo update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
    sudo localedef en_US.UTF-8 -i en_US -f UTF-8
    sudo dpkg-reconfigure locales
#    sudo dpkg-reconfigure console-setup



