#!/bin/bash

sudo apt update

# Configure utils
sudo apt install -y pkg-config
sudo apt install -y libtool
sudo apt install -y automake

# Soft
sudo apt install -y graphviz

# C++
sudo apt install -y clang
sudo update-alternatives --config c++

# C++ libs
sudo apt-get install -y libboost-all-dev
sudo apt-get install -y libcurl4-openssl-dev
sudo apt-get install -y libcurlpp-dev

# For umbrello
#sudo apt install -y kinit kio kio-extras kded5

