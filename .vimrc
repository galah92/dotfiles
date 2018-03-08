set nocompatible        " disable vi compatibility
filetype plugin on
set path+=**            " search in dir of current file, cwd and subdirs

" line numbers
set number              " show line numbers
" set relativenumber      " show relative numbers instead of absolute

" whitespace
set tabstop=4			" number of spaces a tab counts for
set shiftwidth=4		" number of spaces to use for each step of ident
set expandtab			" insert spaces instead of tabs

" backup and swap files
set nobackup            " disable backup files
set noswapfile          " disable swap files
set nowritebackup       " disable auto bakcup before overwriting a file

" theme
syntax enable           " syntax highlighting 
colorscheme desert      " syntax colors
