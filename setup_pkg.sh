#!/bin/bash

    sudo sed -i 's/^.*\/rabbitvcs\/ppa\/ubuntu.*$//g' /etc/apt/sources.list

    sudo apt-get update
    sudo apt-get install exfat-fuse exfat-utils

    sudo apt-get install curl
    sudo apt-get install vim-gtk
    sudo apt-get install font-manager
    sudo apt-get install git-svn
    sudo apt-get install keychain

    sudo apt-get install clang
    sudo update-alternatives --config c++

    sudo dpkg-reconfigure locales
    sudo locale-gen ru_RU.UTF-8 en_US.UTF-8
    sudo update-locale LANG=ru_RU.UTF-8 LANGUAGE=ru_RU:ru:en_US:en
    sudo localedef ru_RU.UTF-8 -i ru_RU -f UTF-8

    # install NeoBundle
    curl https://raw.githubusercontent.com/Shougo/neobundle.vim/master/bin/install.sh | sh
