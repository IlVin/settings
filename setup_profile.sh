#!/bin/bash

    cd ~
    HOMEDIR=`pwd`

    [ -d $HOMEDIR/ilvin.git ] || (mkdir $HOMEDIR/ilvin.git && cd $HOMEDIR/ilvin.git && git clone https://github.com/IlVin/settings.git/ $HOMEDIR/ilvin.git/)

    sudo locale-gen en_US.UTF-8 ru_RU.UTF-8
#    sudo update-locale LANG=ru_RU.UTF-8 LANGUAGE=ru_RU:ru:en_US:en
    sudo update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
    sudo localedef en_US.UTF-8 -i en_US -f UTF-8
    sudo dpkg-reconfigure locales
#    sudo dpkg-reconfigure console-setup

    sed -i 's/^.*\/ilvin\.git\/\.profile.*$//g' $HOMEDIR/.profile
    echo "    . \"$HOMEDIR/ilvin.git/.profile\"" >> $HOMEDIR/.profile

    sed -i 's/^.*\/ilvin\.git\/\.profile.*$//g' $HOMEDIR/.bashrc
    echo "    . \"$HOMEDIR/ilvin.git/.profile\"" >> $HOMEDIR/.bashrc

    [ -f $HOMEDIR/.ssh/config ] && rm -f $HOMEDIR/.ssh/config
    cp $HOMEDIR/ilvin.git/.ssh_config $HOMEDIR/.ssh/config
    chmod a+r,go-w $HOMEDIR/.ssh/config

    git config --global user.email "ilvin@mail.ru"
    git config --global user.name "Ilia Vinokurov"
    git config --global push.default simple
    git config --global receive.denyCurrentBranch ignore

    ln -sf $HOMEDIR/ilvin.git/.tmux.conf $HOMEDIR/.tmux.conf
    ln -sf $HOMEDIR/ilvin.git/.selected_editor $HOMEDIR/.selected_editor
    ln -sf $HOMEDIR/ilvin.git/.gvimrc $HOMEDIR/.gvimrc

    [ -d $HOMEDIR/.fonts ] && rm -rf $HOMEDIR/.fonts
    ln -sf $HOMEDIR/ilvin.git/.fonts $HOMEDIR/.fonts

    [ -d $HOMEDIR/.vim ] && rm -rf $HOMEDIR/.vim
    ln -sf $HOMEDIR/ilvin.git/.vim $HOMEDIR/.vim

    [ -f $HOMEDIR/.vimrc ] && rm -f $HOMEDIR/.vimrc
    cat $HOMEDIR/ilvin.git/.vimrc1 > $HOMEDIR/.vimrc

    [ -d $HOMEDIR/ilvin.git/.vim/bundle/ ] || mkdir $HOMEDIR/ilvin.git/.vim/bundle
    curl https://raw.githubusercontent.com/Shougo/neobundle.vim/master/bin/install.sh | sh
    cat $HOMEDIR/ilvin.git/.vimrc2 >> $HOMEDIR/.vimrc

    [ -d $HOMEDIR/ilvin.git/papercolor-theme ] && cd $HOMEDIR/ilvin.git && rm -rf ./papercolor-theme
    cd $HOMEDIR/ilvin.git && git clone https://github.com/NLKNguyen/papercolor-theme.git ./papercolor-theme
    [ -f $HOMEDIR/ilvin.git/papercolor-theme/colors/PaperColor.vim ] && rm -f $HOMEDIR/.vim/colors/PaperColor.vim
    [ -f $HOMEDIR/ilvin.git/papercolor-theme/colors/PaperColor.vim ] && cp $HOMEDIR/ilvin.git/papercolor-theme/colors/PaperColor.vim $HOMEDIR/.vim/colors
    [ -d $HOMEDIR/ilvin.git/papercolor-theme ] && cd $HOMEDIR/ilvin.git && rm -rf ./papercolor-theme
    cd $HOMEDIR/ilvin.git/.vim/colors/ git commit PaperColor.vim -m 'Update PaperColor.vim'

    # Убрать алерт "Could not apply the stored configuration for the monitor"
    [ -f $HOMEDIR/.config/monitors.xml ] && mv $HOMEDIR/.config/monitors.xml $HOMEDIR/.config/monitors.xml.off

