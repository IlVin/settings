#!/bin/bash

   cd ~
   HOMEDIR=`pwd`

   [ -d $HOMEDIR/ilvin.git ] || (mkdir $HOMEDIR/ilvin.git && cd $HOMEDIR/ilvin.git && git clone https://github.com/IlVin/settings.git/ $HOMEDIR/ilvin.git/)

   sed -i 's/^.*\/ilvin\.git\/\.profile.*$//g' $HOMEDIR/.profile
   echo "    . \"$HOMEDIR/ilvin.git/.profile\"" >> $HOMEDIR/.profile

   sed -i 's/^.*\/ilvin\.git\/\.profile.*$//g' $HOMEDIR/.bashrc
   echo "    . \"$HOMEDIR/ilvin.git/.profile\"" >> $HOMEDIR/.bashrc

   ln -sf $HOMEDIR/ilvin.git/.tmux.conf $HOMEDIR/.tmux.conf
   ln -sf $HOMEDIR/ilvin.git/.selected_editor $HOMEDIR/.selected_editor
   ln -sf $HOMEDIR/ilvin.git/.gvimrc $HOMEDIR/.gvimrc

   [ -d $HOMEDIR/.fonts ] && rm -rf $HOMEDIR/.fonts
   ln -sf $HOMEDIR/ilvin.git/.fonts $HOMEDIR/.fonts

   [ -d $HOMEDIR/.vim ] && rm -rf $HOMEDIR/.vim
   ln -sf $HOMEDIR/ilvin.git/.vim $HOMEDIR/.vim

   [ -f $HOMEDIR/.vimrc ] && rm -f $HOMEDIR/.vimrc
   cat $HOMEDIR/ilvin.git/.vimrc1 > $HOMEDIR/.vimrc

   [ -d $HOMEDIR/ilvin.git/.vim/bundle/ ] || mkdir $HOMEDIR/ilvin.git/.vim/bundle/
   [ -d $HOMEDIR/ilvin.git/.vim/bundle/vim_lib ] && rm -rf $HOMEDIR/ilvin.git/.vim/bundle/vim_lib
#   mkdir $HOMEDIR/ilvin.git/.vim/bundle/vim_lib
#   git clone https://github.com/Bashka/vim_lib.git $HOMEDIR/ilvin.git/.vim/bundle/vim_lib
#   cat $HOMEDIR/ilvin.git/.vimrc2 >> $HOMEDIR/.vimrc

   [ -d $HOMEDIR/ilvin.git/.vim/bundle/vim_lib ] && rm -rf $HOMEDIR/ilvin.git/.vim/bundle/vim_plugmanager
#   mkdir $HOMEDIR/ilvin.git/.vim/bundle/vim_plugmanager
#   git clone https://github.com/Bashka/vim_plugmanager.git $HOMEDIR/ilvin.git/.vim/bundle/vim_plugmanager

   git config --global user.email "ilvin@mail.ru"
   git config --global user.name "Ilia Vinokurov"


   [ -d /home/ilvin.git ] && sudo rm -rf /home/ilvin.git
