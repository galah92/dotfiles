#!/bin/bash

# vim8
add-apt-repository -y ppa:jonathonf/vim

# system update
apt full-upgrade -y
apt update -y
apt upgrade -y
apt autoremove -y

# others
apt -qq -y install build-essential
apt -qq -y install gdb
apt -qq -y install tmux
apt -qq -y install git
apt -qq -y install htop

# python
apt -qq -y install python-pip
apt -qq -y install python3-pip
apt -qq -y install pylint
apt -qq -y install pylint3

# vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# base16 (themes)
git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
