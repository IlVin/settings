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
        clang \

    # For umbrello
    sudo apt-get install kinit kio kio-extras kded5

    sudo update-alternatives --config c++

