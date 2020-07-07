#!/bin/bash

set -x

# System
sudo apt-get install -y \
    gv \
    vim-gtk3 \
    font-manager \

# Gnome utility
sudo apt-get install -y gnome-disk-utility

sudo apt install -y \
    firefox \
    okular \
    gimp \
    libavformat-ffmpeg56 \
    libavfilter-ffmpeg5 \
    gstreamer1.0-libav \
    vlc \

# Remmina
sudo apt-add-repository ppa:remmina-ppa-team/remmina-next
sudo apt-get update
sudo apt-get install remmina remmina-plugin-rdp

# Network Manager
sudo apt install -y network-manager-openvpn
sudo apt install -y network-manager-openvpn-gnome
sudo service network-manager restart

