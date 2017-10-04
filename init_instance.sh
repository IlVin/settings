# Скрипт инициализации вновь созданного инстанса

sudo apt update -y
sudo apt upgrade -y

sudo apt install -y openssh-server
sudo apt install -y net-tools

sudo apt install -y git
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

sudo reboot now


