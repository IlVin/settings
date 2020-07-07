#!/bin/bash

set -x

# Скрипт инициализации вновь созданного инстанса

sudo apt update -y
sudo apt upgrade -y

# System
#sudo apt-get install -y lvm2
#sudo apt-get install -y thin-provisioning-tools
#sudo apt-get install -y smartmontools --no-install-recommends

# Setup environment
sudo apt install -y \
    nmap \
    bash \
    tmux \
    putty \
    mc \
    curl \
    vim \
    rsync \
    jq \
    dconf-tools \
    pv \
    parallel \
    liblz4-tool \
    htop \
    atop \
    sysstat \
    keychain \
    net-tools \
    apt-utils \
    git \
    subversion \
    git-svn \

# OpenSSH
sudo apt install -y openssh-server
[ -d ~/.ssh ] || mkdir ~/.ssh
[ -d ~/.ssh ] && chmod 700 ~/.ssh

# GIT & SVN
git config --global user.email "ilvin@mail.ru"
git config --global user.name "Ilia Vinokurov"
git config --global push.default simple
git config --global receive.denyCurrentBranch ignore

#[ -d ~/ilvin.git/ ] && rm -rf ~/ilvin.git/
#git clone https://github.com/IlVin/settings.git ~/ilvin.git/

# Setup console
#    sudo update-locale LANG=ru_RU.UTF-8 LANGUAGE=ru_RU:ru:en_US:en
sudo locale-gen en_US.UTF-8 ru_RU.UTF-8
sudo update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
sudo localedef en_US.UTF-8 -i en_US -f UTF-8
sudo dpkg-reconfigure locales
sudo apt install -y console-data
sudo dpkg-reconfigure console-setup

# Clean
#sudo apt purge   -y avahi-daemon
sudo apt autoremove

