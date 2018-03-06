#!/bin/bash

sudo apt install -y okular
sudo apt install -y gimp
sudo apt install -y libavformat-ffmpeg56 libavfilter-ffmpeg5 gstreamer1.0-libav
sudo apt install -y vlc
sudo apt purge   -y avahi-daemon

# Telegram
sudo add-apt-repository ppa:atareao/telegram
sudo apt update
sudo apt install -y telegram

sudo apt install -y nautilus-dropbox
