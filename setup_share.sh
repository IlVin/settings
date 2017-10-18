
sudo apt update -y

cd ~
HOMEDIR=`pwd`

sudo mkdir -p /mnt/share/share
sudo mkdir -p /mnt/share/home
sudo mkdir -p /mnt/share/home/ilvin
sudo mkdir -p /mnt/share/home/maria
sudo mkdir -p /mnt/share/home/stephan
sudo mkdir -p /mnt/share/home/sofia
sudo mkdir -p /mnt/share/home/peter
sudo mkdir -p /mnt/share/home/lidia
sudo mkdir -p /mnt/share/home/ivan
sudo chown ilvin:ilvin -R /mnt/share

sudo useradd -d /dev/null -s /sbin/nologin maria
sudo useradd -d /dev/null -s /sbin/nologin stephan
sudo useradd -d /dev/null -s /sbin/nologin sofia
sudo useradd -d /dev/null -s /sbin/nologin peter
sudo useradd -d /dev/null -s /sbin/nologin lidia
sudo useradd -d /dev/null -s /sbin/nologin ivan

sudo apt install -y samba
sudo cp /etc/samba/smb.conf{,.bak}
sudo rm -f /etc/samba/smb.conf
sudo cp $HOMEDIR/ilvin.git/smb.conf /etc/samba/smb.conf
sudo service smbd restart

sudo mkdir -p /mnt/dlna/videos
sudo mkdir -p /mnt/dlna/pictures
sudo mkdir -p /mnt/dlna/music
sudo mkdir -p sudo chown ilvin:ilvin -R /mnt/dlna

sudo apt install -y minidlna inotify-tools
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
sudo cp /etc/minidlna.conf{,.bak}
sudo rm -f /etc/minidlna.conf
sudo cp $HOMEDIR/ilvin.git/minidlna.conf /etc/minidlna.conf
sudo service minidlna restart



