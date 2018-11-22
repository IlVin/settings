#!/bin/bash

# Docker
LSB=`lsb_release --codename --short`
LSB="zesty"
sudo apt install -y software-properties-common
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo apt-add-repository "deb https://apt.dockerproject.org/repo ubuntu-${LSB} main"
sudo apt update
sudo apt-get install -y docker-engine
apt-cache policy docker-engine
sudo usermod -aG docker $(whoami)
sudo systemctl --no-pager status docker

