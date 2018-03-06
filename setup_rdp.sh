sudo apt update -y
sudo apt upgrade -y

cd ~
HOMEDIR=`pwd`

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

sudo apt autoremove -y
