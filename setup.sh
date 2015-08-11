#/bin/bash

   sudo apt-get update
   sudo apt-get install vim
   sudo apt-get install git
   sudo apt-get install mc
#   sudo apt-get install font-manager

   echo "    . \"/home/ilvin.git/.profile\"" >> ~/.profile

   rm -f ~/.tmux.conf
   ln -s /home/ilvin.git/.tmux.conf ~/.tmux.conf

   rm -f ~/.selected_editor
   ln -s /home/ilvin.git/.selected_editor ~/.selected_editor

   rm -f ~/.fonts
   ln -s /home/ilvin.git/.fonts ~/.fonts

   rm -f ~/.vim
   ln -s /home/ilvin.git/.vim ~/.vim

   rm -f ~/.vimrc
   ln -s /home/ilvin.git/.vimrc ~/.vimrc

   rm -f ~/.gvimrc
   ln -s /home/ilvin.git/.gvimrc ~/.gvimrc

