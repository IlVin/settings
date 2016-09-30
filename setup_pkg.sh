#!/bin/bash

    sudo sed -i 's/^.*\/rabbitvcs\/ppa\/ubuntu.*$//g' /etc/apt/sources.list

    sudo apt-get update
    sudo apt-get install \
        exfat-fuse \
        exfat-utils \
        pkg-config \
        libtool \
        automake \
        graphviz \
        gv \
        pv \
        parallel \
        liblz4-tool \
        curl \
        htop \
        sysstat \
        vim-gtk \
        font-manager \
        subversion \
        git-svn \
        keychain \
        clang \


        sudo update-alternatives --config c++

