#!/bin/bash

    sudo sed -i 's/^.*\/rabbitvcs\/ppa\/ubuntu.*$//g' /etc/apt/sources.list

    sudo apt-get update
    sudo apt-get install exfat-fuse exfat-utils
    sudo apt-get install pkg-config libtool automake
    sudo apt-get install pv
    sudo apt-get install liblz4-tool
    sudo apt-get install curl
    sudo apt-get install vim-gtk
    sudo apt-get install font-manager
    sudo apt-get install git-svn
    sudo apt-get install keychain

    sudo apt-get install clang


    sudo update-alternatives --config c++

