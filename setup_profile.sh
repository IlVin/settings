#!/bin/bash

   sed -i 's/^.*\/home\/ilvin\.git\/\.profile.*$//' ~/.profile
   echo "    . \"/home/ilvin.git/.profile\"" >> ~/.profile

   sed -i 's/^.*\/home\/ilvin\.git\/\.profile.*$//' ~/.bashrc
   echo "    . \"/home/ilvin.git/.profile\"" >> ~/.bashrc

   [ -f ~/.tmux.conf ] && rm -f ~/.tmux.conf
   ln -s /home/ilvin.git/.tmux.conf ~/.tmux.conf

   [ -f ~/.selected_editor ] && rm -f ~/.selected_editor
   ln -s /home/ilvin.git/.selected_editor ~/.selected_editor

   [ -d ~/.fonts ] && rm -f ~/.fonts
   ln -s /home/ilvin.git/.fonts ~/.fonts

   [ -d ~/.vim ] && rm -f ~/.vim
   ln -s /home/ilvin.git/.vim ~/.vim

   [ -f ~/.gvimrc ] && rm -f ~/.gvimrc
   ln -s /home/ilvin.git/.gvimrc ~/.gvimrc

   [ -f ~/.vimrc ] && rm -f ~/.vimrc
   cat /home/ilvin.git/.vimrc1 > ~/.vimrc

   [ -d /home/ilvin.git/.vim/bundle/ ] || mkdir /home/ilvin.git/.vim/bundle/
   [ -d /home/ilvin.git/.vim/bundle/vim_lib ] && rm -rf /home/ilvin.git/.vim/bundle/vim_lib
#   mkdir /home/ilvin.git/.vim/bundle/vim_lib
#   git clone https://github.com/Bashka/vim_lib.git /home/ilvin.git/.vim/bundle/vim_lib
#   cat /home/ilvin.git/.vimrc2 >> ~/.vimrc

   [ -d /home/ilvin.git/.vim/bundle/vim_lib ] && rm -rf /home/ilvin.git/.vim/bundle/vim_plugmanager
#   mkdir /home/ilvin.git/.vim/bundle/vim_plugmanager
#   git clone https://github.com/Bashka/vim_plugmanager.git /home/ilvin.git/.vim/bundle/vim_plugmanager

   git config --global user.email "ilvin@mail.ru"
   git config --global user.name "Ilia Vinokurov"

