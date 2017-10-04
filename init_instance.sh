# Скрипт инициализации вновь созданного инстанса

sudo apt update -y
sudo apt upgrade -y
sudo apt install git -y
git clone https://github.com/IlVin/settings.git ~/ilvin.git/

# Setup console
sudo locale-gen en_US.UTF-8 ru_RU.UTF-8
#    sudo update-locale LANG=ru_RU.UTF-8 LANGUAGE=ru_RU:ru:en_US:en
sudo update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
sudo localedef en_US.UTF-8 -i en_US -f UTF-8
sudo dpkg-reconfigure locales

sudo reboot now


