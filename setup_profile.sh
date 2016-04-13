#!/bin/bash

    cd ~
    HOMEDIR=`pwd`

    [ -d $HOMEDIR/ilvin.git ] || (mkdir $HOMEDIR/ilvin.git && cd $HOMEDIR/ilvin.git && git clone https://github.com/IlVin/settings.git/ $HOMEDIR/ilvin.git/)

    sudo dpkg-reconfigure locales
    sudo locale-gen ru_RU.UTF-8 en_US.UTF-8
    sudo update-locale LANG=ru_RU.UTF-8 LANGUAGE=ru_RU:ru:en_US:en
    sudo localedef ru_RU.UTF-8 -i ru_RU -f UTF-8

    sed -i 's/^.*\/ilvin\.git\/\.profile.*$//g' $HOMEDIR/.profile
    echo "    . \"$HOMEDIR/ilvin.git/.profile\"" >> $HOMEDIR/.profile

    sed -i 's/^.*\/ilvin\.git\/\.profile.*$//g' $HOMEDIR/.bashrc
    echo "    . \"$HOMEDIR/ilvin.git/.profile\"" >> $HOMEDIR/.bashrc

    [ -f $HOMEDIR/.ssh/config ] && rm -f $HOMEDIR/.ssh/config
    cp $HOMEDIR/ilvin.git/.ssh_config $HOMEDIR/.ssh/config
    chmod a+r,go-w $HOMEDIR/.ssh/config

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

    git config --global user.email "ilvin@mail.ru"
    git config --global user.name "Ilia Vinokurov"

    # Убрать алерт "Could not apply the stored configuration for the monitor"
    [ -f $HOMEDIR/.config/monitors.xml ] && mv $HOMEDIR/.config/monitors.xml $HOMEDIR/.config/monitors.xml.off

    git config --global push.default simple
    git config --global receive.denyCurrentBranch ignore

    [ -d /home/ilvin.git ] && sudo rm -rf /home/ilvin.git

