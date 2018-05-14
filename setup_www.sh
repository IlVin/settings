
# Setup WWW soft

# NGINX
sudo apt update
sudo apt install -y nginx

# SSL
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:certbot/certbot
sudo apt update
sudo apt install -y python-certbot-nginx 
sudo certbot --nginx

# Docker
sudo apt install -y software-properties-common
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
sudo apt update
sudo apt-get install -y docker-engine
apt-cache policy docker-engine
sudo usermod -aG docker $(whoami)
sudo systemctl --no-pager status docker
sudo curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
