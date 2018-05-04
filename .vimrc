" install vim-plug if need to
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" set vim-plug plugins
call plug#begin('~/.vim/plugged')
Plug 'w0rp/ale'                         " linting
Plug 'altercation/vim-colors-solarized'
call plug#end()

" base
set nocompatible                        " vim, not vi
syntax on                               " syntax highlighting
filetype plugin indent on               " recognise filetype, load plugins and indent files
set path+=**                            " search in dir of current file, cwd and subdirs

" interface
set number                              " show line numbers

" whitespace
set tabstop=4			                " number of spaces a tab counts for
set shiftwidth=4		                " number of spaces to use for each step of ident
set expandtab			                " insert spaces instead of tabs

" searching
set hlsearch                            " highlight search matches
set incsearch                           " search as you type

" backup and swap files
set nobackup                            " disable backup files
set noswapfile                          " disable swap files
set nowritebackup                       " disable auto bakcup before overwriting a file

" theme
syntax enable                           " syntax highlighting
set background=light
colorscheme solarized
"set t_Co=256
set t_ut=

" ale
let g:ale_python_pylint_executable='pylint3'
