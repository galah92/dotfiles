#!/bin/bash
apt full-upgrade -y
apt update -y
apt upgrade -y
apt autoremove -y

apt -qq -y install build-essential
apt -qq -y install vim
apt -qq -y install tmux
apt -qq -y install git
apt -qq -y install python3
apt -qq -y install python3-pip
apt -qq -y install htop

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash     # installing nvm
nvm install latest

git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
