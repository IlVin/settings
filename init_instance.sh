#!/bin/bash

# Скрипт инициализации вновь созданного инстанса

sudo apt update -y
sudo apt upgrade -y

cd ~
HOMEDIR=`pwd`

# System
sudo apt-get install -y lvm2
sudo apt-get install -y thin-provisioning-tools
sudo apt-get install -y smartmontools --no-install-recommends

# Setup environment
sudo apt install -y nmap
sudo apt install -y bash
sudo apt install -y tmux
sudo apt install -y putty
sudo apt install -y mc
sudo apt install -y curl
sudo apt install -y vim
sudo apt install -y rsync

sudo apt install -y dconf-tools
sudo apt install -y gv
sudo apt install -y pv
sudo apt install -y parallel
sudo apt install -y liblz4-tool
sudo apt install -y htop
sudo apt install -y sysstat
sudo apt install -y keychain

sudo apt install -y net-tools

# OpenSSH
sudo apt install -y openssh-server
[ -d ~/.ssh ] || mkdir ~/.ssh
[ -d ~/.ssh ] && chmod 700 ~/.ssh

# GIT & SVN
sudo apt install -y git
git config --global user.email "ilvin@mail.ru"
git config --global user.name "Ilia Vinokurov"
git config --global push.default simple
git config --global receive.denyCurrentBranch ignore
sudo apt install -y subversion
sudo apt install -y git-svn

[ -d ~/ilvin.git/ ] && rm -rf ~/ilvin.git/
git clone https://github.com/IlVin/settings.git ~/ilvin.git/

# Setup console
#    sudo update-locale LANG=ru_RU.UTF-8 LANGUAGE=ru_RU:ru:en_US:en
sudo locale-gen en_US.UTF-8 ru_RU.UTF-8
sudo update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
sudo localedef en_US.UTF-8 -i en_US -f UTF-8
sudo dpkg-reconfigure locales
sudo apt install -y console-data
sudo dpkg-reconfigure console-setup

# Clean
sudo apt purge   -y avahi-daemon
sudo apt autoremove

