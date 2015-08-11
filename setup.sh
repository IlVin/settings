#/bin/bash

   sudo apt-get update
   sudo apt-get install vim
   sudo apt-get install git
   sudo apt-get install mc

   echo "    . \"/home/ilvin.git/.profile\"" >> ~/.profile

   rm -f ~/.tmux.conf
   ln -s /home/ilvin.git/.tmux.conf ~/.tmux.conf

   rm -f ~/.selected_editor
   ln -s /home/ilvin.git/.selected_editor ~/.selected_editor

