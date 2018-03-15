
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
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
apt-cache policy docker-engine
sudo apt update
sudo apt-get install -y docker-engine
sudo usermod -aG docker $(whoami)
sudo systemctl --no-pager status docker


