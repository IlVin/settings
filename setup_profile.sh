#!/bin/bash

   [ -d /home/ilvin.git ] && rm -rf /home/ilvin.git
   [ -d ~/ilvin.git ] || mkdir ~/ilvin.git && git clone https://github.com/IlVin/settings.git/ ~/ilvin.git/

   sed -i 's/^.*\/home\/ilvin\.git\/\.profile.*$//' ~/.profile
   sed -i 's/^.*~\/ilvin\.git\/\.profile.*$//' ~/.profile
   echo "    . \"~/ilvin.git/.profile\"" >> ~/.profile

   sed -i 's/^.*\/home\/ilvin\.git\/\.profile.*$//' ~/.bashrc
   sed -i 's/^.*~\/ilvin\.git\/\.profile.*$//' ~/.bashrc
   echo "    . \"~/ilvin.git/.profile\"" >> ~/.bashrc

   [ -f ~/.tmux.conf ] && rm -f ~/.tmux.conf
   ln -s ~/ilvin.git/.tmux.conf ~/.tmux.conf

   [ -f ~/.selected_editor ] && rm -f ~/.selected_editor
   ln -s ~/ilvin.git/.selected_editor ~/.selected_editor

   [ -d ~/.fonts ] && rm -f ~/.fonts
   ln -s ~/ilvin.git/.fonts ~/.fonts

   [ -d ~/.vim ] && rm -f ~/.vim
   ln -s ~/ilvin.git/.vim ~/.vim

   [ -f ~/.gvimrc ] && rm -f ~/.gvimrc
   ln -s ~/ilvin.git/.gvimrc ~/.gvimrc

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

