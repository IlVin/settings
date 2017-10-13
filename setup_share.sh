
cd ~
HOMEDIR=`pwd`

[ -f /mnt/share/ ] || sudo mkdir /mnt/share
[ -f /mnt/share/share ] || sudo mkdir /mnt/share/share
[ -f /mnt/share/home ] || sudo mkdir /mnt/share/home
[ -f /mnt/share/home/ilvin ] || sudo mkdir /mnt/share/home/ilvin
[ -f /mnt/share/home/maria ] || sudo mkdir /mnt/share/home/maria
[ -f /mnt/share/home/stephan ] || sudo mkdir /mnt/share/home/stephan
[ -f /mnt/share/home/sofia ] || sudo mkdir /mnt/share/home/sofia
[ -f /mnt/share/home/peter ] || sudo mkdir /mnt/share/home/peter
[ -f /mnt/share/home/lidia ] || sudo mkdir /mnt/share/home/lidia
[ -f /mnt/share/home/ivan ] || sudo mkdir /mnt/share/home/ivan
sudo chown ilvin:ilvin -R /mnt/share

sudo useradd -d /dev/null -s /sbin/nologin maria
sudo useradd -d /dev/null -s /sbin/nologin stephan
sudo useradd -d /dev/null -s /sbin/nologin sofia
sudo useradd -d /dev/null -s /sbin/nologin peter
sudo useradd -d /dev/null -s /sbin/nologin lidia
sudo useradd -d /dev/null -s /sbin/nologin ivan

sudo apt update -y
sudo apt install -y samba
sudo cp /etc/samba/smb.conf{,.bak}
sudo rm -f /etc/samba/smb.conf
sudo cp $HOMEDIR/ilvin.git/smb.conf /etc/samba/smb.conf
sudo service smbd restart


