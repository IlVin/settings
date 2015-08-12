#!/bin/bash

   [ -d /home/ilvin.git ] && sudo rm -rf /home/ilvin.git
   [ -d ~/ilvin.git ] || (mkdir ~/ilvin.git && git clone https://github.com/IlVin/settings.git/ ~/ilvin.git/)

   sed -i 's/^.*\/home\/ilvin\.git\/\.profile.*$//' ~/.profile
   sed -i 's/^.*~\/ilvin\.git\/\.profile.*$//' ~/.profile
   echo "    . \"~/ilvin.git/.profile\"" >> ~/.profile

   sed -i 's/^.*\/home\/ilvin\.git\/\.profile.*$//' ~/.bashrc
   sed -i 's/^.*~\/ilvin\.git\/\.profile.*$//' ~/.bashrc
   echo "    . \"~/ilvin.git/.profile\"" >> ~/.bashrc

   ln -sf ~/ilvin.git/.tmux.conf ~/.tmux.conf
   ln -sf ~/ilvin.git/.selected_editor ~/.selected_editor
   ln -sf ~/ilvin.git/.gvimrc ~/.gvimrc

   [ -d ~/.fonts ] && rm -rf ~/.fonts
   ln -sf ~/ilvin.git/.fonts ~/.fonts

   [ -d ~/.vim ] && rm -rf ~/.vim
   ln -sf ~/ilvin.git/.vim ~/.vim

   [ -f ~/.vimrc ] && rm -f ~/.vimrc
   cat ~/ilvin.git/.vimrc1 > ~/.vimrc

   [ -d ~/ilvin.git/.vim/bundle/ ] || mkdir ~/ilvin.git/.vim/bundle/
   [ -d ~/ilvin.git/.vim/bundle/vim_lib ] && rm -rf ~/ilvin.git/.vim/bundle/vim_lib
#   mkdir ~/ilvin.git/.vim/bundle/vim_lib
#   git clone https://github.com/Bashka/vim_lib.git ~/ilvin.git/.vim/bundle/vim_lib
#   cat ~/ilvin.git/.vimrc2 >> ~/.vimrc

   [ -d ~/ilvin.git/.vim/bundle/vim_lib ] && rm -rf ~/ilvin.git/.vim/bundle/vim_plugmanager
#   mkdir ~/ilvin.git/.vim/bundle/vim_plugmanager
#   git clone https://github.com/Bashka/vim_plugmanager.git ~/ilvin.git/.vim/bundle/vim_plugmanager

   git config --global user.email "ilvin@mail.ru"
   git config --global user.name "Ilia Vinokurov"

