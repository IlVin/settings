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
sudo apt-get install -y nmap
sudo apt-get install -y bash
sudo apt-get install -y tmux
sudo apt-get install -y putty
sudo apt-get install -y mc
sudo apt-get install -y curl
sudo apt-get install -y vim
sudo apt-get install -y vim-gtk3
sudo apt-get install -y rsync

sudo apt-get install -y dconf-tools
sudo apt-get install -y gv
sudo apt-get install -y pv
sudo apt-get install -y parallel
sudo apt-get install -y liblz4-tool
sudo apt-get install -y htop
sudo apt-get install -y sysstat
sudo apt-get install -y font-manager
sudo apt-get install -y keychain

sudo apt-get install -y subversion
sudo apt-get install -y git-svn
sudo apt install -y net-tools

# OpenSSH
sudo apt install -y openssh-server
[ -d ~/.ssh ] || mkdir ~/.ssh
[ -d ~/.ssh ] && chmod 700 ~/.ssh

# Gnome utility
sudo apt-get install -y gnome-disk-utility

# GIT
sudo apt install -y git
[ -d ~/ilvin.git/ ] && rm -rf ~/ilvin.git/
git clone https://github.com/IlVin/settings.git ~/ilvin.git/

# Setup console
#    sudo update-locale LANG=ru_RU.UTF-8 LANGUAGE=ru_RU:ru:en_US:en
sudo locale-gen en_US.UTF-8 ru_RU.UTF-8
sudo update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
sudo localedef en_US.UTF-8 -i en_US -f UTF-8
sudo dpkg-reconfigure locales
sudo apt install -y console-data
#sudo dpkg-reconfigure console-data
sudo dpkg-reconfigure console-setup

# GUI
sudo apt install -y firefox
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

# Network Manager
sudo apt install -y network-manager-openvpn
sudo apt install -y network-manager-openvpn-gnome
sudo service network-manager restart

# Clean
sudo apt autoremove
sudo reboot now

