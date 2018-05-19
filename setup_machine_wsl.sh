#!/bin/bash

# system update
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
apt -qq -y install python3
apt -qq -y install python3-pip
apt -qq -y install pylint3
