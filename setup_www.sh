
# Setup WWW soft

sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
apt-cache policy docker-engine
sudo apt update
sudo apt-get install -y docker-engine
sudo usermod -aG docker $(whoami)
sudo systemctl --no-pager status docker


