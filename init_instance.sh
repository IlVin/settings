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

# Setup Xfce4
sudo apt-get install -y xfce4
sudo apt-get install -y xfce4-session
sudo apt-get install -y xfce4-goodies
sudo xfconf-query -c xfce4-session -p /startup/ssh-agent/type -n -t string -s ssh-agent
# NEED TO SET: [Settings]->[Session and Startup]->[Advanced]->[Launch GNOME services on startup]

# Turn off energy control and screen saver
sudo xset s off
sudo xset dpms 0 0 0
sudo xset -dpms

# Gnome utility
sudo apt-get install -y gnome-disk-utility

# Setup Display manager
defdm=`head -n1 /etc/X11/default-display-manager 2>/dev/null`
if ! [ -f "$defdm" ]; then
    echo "Setup SLIM DM"
    sudo apt-get install -y slim
fi

# GIT
sudo apt install -y git
[ -d ~/ilvin.git/ ] && rm -rf ~/ilvin.git/
git clone https://github.com/IlVin/settings.git ~/ilvin.git/

# Setup console
sudo locale-gen en_US.UTF-8 ru_RU.UTF-8
#    sudo update-locale LANG=ru_RU.UTF-8 LANGUAGE=ru_RU:ru:en_US:en
sudo update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
sudo localedef en_US.UTF-8 -i en_US -f UTF-8
sudo dpkg-reconfigure locales
sudo apt install -y console-data
sudo dpkg-reconfigure console-data
sudo dpkg-reconfigure console-setup

sudo apt autoremove
sudo reboot now

