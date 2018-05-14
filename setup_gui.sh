#!/bin/bash

cd ~
HOMEDIR=`pwd`

# System
sudo apt-get install -y vim-gtk3
sudo apt-get install -y font-manager

# Gnome utility
sudo apt-get install -y gnome-disk-utility

sudo apt install -y firefox
sudo apt install -y okular
sudo apt install -y gimp
sudo apt install -y libavformat-ffmpeg56 libavfilter-ffmpeg5 gstreamer1.0-libav
sudo apt install -y vlc

# Remmina
sudo apt-add-repository ppa:remmina-ppa-team/remmina-next
sudo apt-get update
sudo apt-get install remmina remmina-plugin-rdp

# Network Manager
sudo apt install -y network-manager-openvpn
sudo apt install -y network-manager-openvpn-gnome
sudo service network-manager restart

