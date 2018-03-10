[[ $- != *i* ]] && return   # if not running interactively, don't do anything

HISTCONTROL=ignoreboth      # ignore spaces and duplicates in the history
shopt -s histappend         # append to history file, don't override it

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;34m\]\W\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

export EDITOR=vim

set editing-mode vi

case $(uname) in
    'Linux')    LS_FLAGS='--color=auto --group-directories-first' ;;
    'Darwin')   LS_FLAGS='-Gh' ;;
esac

# Alias definitions.
alias c="clear"
alias ls="ls $LS_FLAGS"
alias ll="ls -l"
alias la="ls -la"
alias tl="tmux ls"
alias reload="source ~/.bashrc && echo '- .bashrc reloaded.'"

# enable nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


BASE16_SHELL=$HOME/.config/base16-shell/
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"
