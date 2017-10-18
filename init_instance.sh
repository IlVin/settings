# Скрипт инициализации вновь созданного инстанса

sudo apt update -y
sudo apt upgrade -y

cd ~
HOMEDIR=`pwd`

# System
sudo apt-get install -y lvm2
sudo apt-get install -y thin-provisioning-tools

# Setup environment
sudo apt-get install -y nmap
sudo apt-get install -y bash
sudo apt-get install -y tmux
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

# Setup VNC
sudo apt-get install -y x11vnc
sudo service x11vnc stop
sudo systemctl disable x11vnc.service
[ -f /etc/systemd/system/x11vnc.service ] && sudo rm -f /etc/systemd/system/x11vnc.service
[ -f /etc/vnc/x11vnc.passwd ] && sudo rm -f /etc/vnc/x11vnc.passwd
[ -d /etc/vnc/ ] || sudo mkdir /etc/vnc/
dmauth=`ps wwaux | grep 'Xorg' | grep -Po '\-auth [^ ]+' | cut -d' ' -f2 | head -n1`
if [ "$dmauth" == "/var/run/slim.auth" ] || [ "$dmauth" == "" ]; then
    echo "Set SLIM as default DM"
    sudo sh -c 'echo "/usr/bin/slim" > /etc/X11/default-display-manager'
    sudo cp $HOMEDIR/ilvin.git/x11vnc.service.slim /etc/systemd/system/x11vnc.service
else
    sudo cp $HOMEDIR/ilvin.git/x11vnc.service /etc/systemd/system/x11vnc.service
fi
sudo x11vnc -storepasswd 123 /etc/vnc/x11vnc.passwd
sudo systemctl daemon-reload
sudo systemctl enable x11vnc.service

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

