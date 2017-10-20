
sudo apt update -y

cd ~
HOMEDIR=`pwd`

# MNT
sudo mkdir -p /mnt/mirror
sudo mkdir -p /mnt/data
sudo chown ilvin:ilvin -R /mnt/mirror
sudo chown ilvin:ilvin -R /mnt/data

# HOMES
sudo mkdir -p /mnt/mirror/homes
sudo mkdir -p /mnt/data/homes
sudo mkdir -p /mnt/data/homes/logs
sudo mkdir -p /mnt/data/homes/ilvin
sudo mkdir -p /mnt/data/homes/maria
sudo mkdir -p /mnt/data/homes/stephan
sudo mkdir -p /mnt/data/homes/sofia
sudo mkdir -p /mnt/data/homes/peter
sudo mkdir -p /mnt/data/homes/lidia
sudo mkdir -p /mnt/data/homes/ivan
sudo chown ilvin:ilvin -R /mnt/mirror/homes
sudo chown ilvin:ilvin -R /mnt/data/homes

# SHARE
sudo mkdir -p /mnt/mirror/share
sudo mkdir -p /mnt/data/share
sudo mkdir -p /mnt/data/share/logs
sudo mkdir -p /mnt/data/share/data
sudo chown ilvin:ilvin -R /mnt/mirror/share
sudo chown ilvin:ilvin -R /mnt/data/share

sudo useradd -d /dev/null -s /sbin/nologin maria
sudo useradd -d /dev/null -s /sbin/nologin stephan
sudo useradd -d /dev/null -s /sbin/nologin sofia
sudo useradd -d /dev/null -s /sbin/nologin peter
sudo useradd -d /dev/null -s /sbin/nologin lidia
sudo useradd -d /dev/null -s /sbin/nologin ivan

sudo service smbd stop
sudo apt install -y samba
sudo cp /etc/samba/smb.conf{,.bak}
sudo rm -f /etc/samba/smb.conf
sudo cp $HOMEDIR/ilvin.git/smb.conf /etc/samba/smb.conf
sudo service smbd restart

# DLNA
sudo mkdir -p /mnt/mirror/dlna
sudo mkdir -p /mnt/data/dlna
sudo mkdir -p /mnt/data/dlna/logs
sudo mkdir -p /mnt/data/dlna/videos
sudo mkdir -p /mnt/data/dlna/pictures
sudo mkdir -p /mnt/data/dlna/music
sudo chown ilvin:ilvin -R /mnt/mirror/dlna
sudo chown ilvin:ilvin -R /mnt/data/dlna

sudo mkdir -p /mnt/data/dlna/cache
sudo chown minidlna:minidlna -R /mnt/data/dlna/cache

sudo service minidlna stop
sudo apt install -y minidlna inotify-tools
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
sudo cp /etc/minidlna.conf{,.bak}
sudo rm -f /etc/minidlna.conf
sudo cp $HOMEDIR/ilvin.git/minidlna.conf /etc/minidlna.conf
sudo service minidlna start


