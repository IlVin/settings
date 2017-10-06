#!/bin/bash

cd ~
HOMEDIR=`pwd`

sudo apt-get update
sudo apt-get upgrade -y

# Setup environment
sudo apt-get install -y nmap
sudo apt-get install -y bash
sudo apt-get install -y tmux
sudo apt-get install -y mc
sudo apt-get install -y curl
sudo apt-get install -y vim
sudo apt-get install -y vim-gtk3

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

# Setup Xfce4
sudo apt-get install -y xfce4
sudo apt-get install -y xfce4-session
sudo apt-get install -y xfce4-goodies
#sed -i 's/^.*startxfce4 [&].*$//g' $HOMEDIR/.vnc/xstartup
#echo -e "\nstartxfce4 &\n" >> $HOMEDIR/.vnc/xstartup
#sudo chmod a+x $HOMEDIR/.vnc/xstartup

# Setup Display manager
sudo apt-get install -y slim
defdm=`head -n1 /etc/X11/default-display-manager 2>/dev/null`
if ! [ -f "$defdm" ]; then
    echo "Set SLIM as default DM"
    sudo sh -c 'echo "/usr/bin/slim" > /etc/X11/default-display-manager'
fi

# Setup VNC
sudo apt-get install -y x11vnc
sudo service x11vnc stop
sudo systemctl disable x11vnc.service
[ -f /etc/systemd/system/x11vnc.service ] && sudo rm -f /etc/systemd/system/x11vnc.service
[ -f /etc/vnc/x11vnc.passwd ] && sudo rm -f /etc/vnc/x11vnc.passwd
[ -d /etc/vnc/ ] || sudo mkdir /etc/vnc/
sudo x11vnc -storepasswd /etc/vnc/x11vnc.passwd

dmauth=`ps wwaux | grep 'Xorg' | grep -Po '\-auth [^ ]+' | cut -d' ' -f2 | head -n1`
if [ "$dmauth" == "/var/run/slim.auth" ]; then
    sudo cp $HOMEDIR/ilvin.git/x11vnc.service.slim /etc/systemd/system/x11vnc.service
else
    sudo cp $HOMEDIR/ilvin.git/x11vnc.service /etc/systemd/system/x11vnc.service
fi
sudo systemctl daemon-reload
sudo systemctl enable x11vnc.service
sudo service x11vnc start

sudo systemctl --no-pager status x11vnc.service
sleep 5
sudo netstat -nltp

