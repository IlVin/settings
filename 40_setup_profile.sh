#!/bin/bash

set -x

    [ -d $HOME/ilvin.git ] || (mkdir $HOME/ilvin.git && cd $HOME/ilvin.git && git clone https://github.com/IlVin/settings.git/ $HOME/ilvin.git/)

    sed -i 's/^.*\/ilvin\.git\/\.profile.*$//g' $HOME/.profile
    echo "    . \"$HOME/ilvin.git/.profile\"" >> $HOME/.profile

    sed -i 's/^.*\/ilvin\.git\/\.profile.*$//g' $HOME/.bashrc
    echo "    . \"$HOME/ilvin.git/.profile\"" >> $HOME/.bashrc

    [ -f $HOME/.ssh/config ] && rm -f $HOME/.ssh/config
    cp $HOME/ilvin.git/.ssh_config $HOME/.ssh/config
    chmod a+r,go-w $HOME/.ssh/config

    git config --global user.email "ilvin@mail.ru"
    git config --global user.name "Ilia Vinokurov"
    git config --global push.default simple
    git config --global receive.denyCurrentBranch ignore

    ln -sf $HOME/ilvin.git/.tmux.conf $HOME/.tmux.conf
    ln -sf $HOME/ilvin.git/.selected_editor $HOME/.selected_editor
    ln -sf $HOME/ilvin.git/.gvimrc $HOME/.gvimrc

    [ -d $HOME/.fonts ] && rm -rf $HOME/.fonts
    ln -sf $HOME/ilvin.git/.fonts $HOME/.fonts

    [ -d $HOME/.vim ] && rm -rf $HOME/.vim
    ln -sf $HOME/ilvin.git/.vim $HOME/.vim

    [ -f $HOME/.vimrc ] && rm -f $HOME/.vimrc
    cat $HOME/ilvin.git/.vimrc1 > $HOME/.vimrc

    [ -d $HOME/ilvin.git/.vim/bundle/ ] || mkdir $HOME/ilvin.git/.vim/bundle
    cat $HOME/ilvin.git/.vimrc2 >> $HOME/.vimrc

    [ -d $HOME/ilvin.git/papercolor-theme ] && cd $HOME/ilvin.git && rm -rf ./papercolor-theme
    cd $HOME/ilvin.git && git clone https://github.com/NLKNguyen/papercolor-theme.git ./papercolor-theme
    [ -f $HOME/ilvin.git/papercolor-theme/colors/PaperColor.vim ] && rm -f $HOME/.vim/colors/PaperColor.vim
    [ -f $HOME/ilvin.git/papercolor-theme/colors/PaperColor.vim ] && cp $HOME/ilvin.git/papercolor-theme/colors/PaperColor.vim $HOME/.vim/colors
    [ -d $HOME/ilvin.git/papercolor-theme ] && cd $HOME/ilvin.git && rm -rf ./papercolor-theme
    cd $HOME/ilvin.git/.vim/colors/ && git commit PaperColor.vim -m 'Update PaperColor.vim'

    # Убрать алерт "Could not apply the stored configuration for the monitor"
    [ -f $HOME/.config/monitors.xml ] && mv $HOME/.config/monitors.xml $HOME/.config/monitors.xml.off

