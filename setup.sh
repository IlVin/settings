#/bin/bash

   sudo apt-get update
   sudo apt-get install vim
   sudo apt-get install git
   sudo apt-get install mc

   echo "    . \"/home/ilvin.git/.profile\"" >> ~/.profile

   ln -s /home/ilvin.git/.tmux.conf ~/.tmux.conf

