[[ $- != *i* ]] && return   # if not running interactively, don't do anything

HISTCONTROL=ignoreboth      # ignore spaces and duplicates in the history
shopt -s histappend         # append to history file, don't override it

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

set editing-mode vi

case $(uname) in
    'Linux')    LS_FLAGS='--color=auto --group-directories-first' ;;
    'Darwin')   LS_FLAGS='-Gh' ;;
esac

# Alias definitions.
alias ls="ls $LS_FLAGS"
alias ll="ls -l"
alias la="ls -la"

# enable programmable completion features
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
