#!/bin/bash

sudo apt update

# Configure utils
sudo apt install -y pkg-config
sudo apt install -y libtool
sudo apt install -y automake

# Java
echo oracle-java9-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
sudo apt-get install -y oracle-java9-installer
# If you want to make Oracle Java 9 default
sudo apt-get install -y oracle-java9-set-default
# sudo apt-get install --no-install-recommends oracle-java9-installer

# Soft
sudo apt install -y graphviz

# C++
sudo apt install -y build-essential
sudo apt install -y clang
sudo update-alternatives --config c++

# C++ libs
sudo apt-get install -y libboost-all-dev
sudo apt-get install -y libcurl4-openssl-dev
sudo apt-get install -y libcurlpp-dev

# Python
sudo apt install -y python python-pip
sudo -H pip install --upgrade pip
sudo apt-get -y install python-dev python-setuptools python-requests libxml2-dev libxslt1-dev libz-dev
sudo apt-get -y install libffi-dev libssl-dev
sudo apt --auto-remove --yes purge python-openssl
sudo apt install --reinstall python-openssl -y
sudo pip install setuptools --upgrade
sudo python -m easy_install --upgrade pyOpenSSL
sudo -H pip install --upgrade cryptography
sudo -H pip install --upgrade zstandard

# For umbrello
#sudo apt install -y kinit kio kio-extras kded5

