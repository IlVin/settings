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

# Telegram
#sudo add-apt-repository ppa:atareao/telegram
#sudo apt update
#sudo apt install -y telegram

# Dropbox
#sudo apt install -y nautilus-dropbox

# Network Manager
sudo apt install -y network-manager-openvpn
sudo apt install -y network-manager-openvpn-gnome
sudo service network-manager restart
