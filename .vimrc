
call plug#begin('~/.vim/plugged')
" Plug 'chriskempson/base16-vim'      " themes
Plug 'w0rp/ale'                     " ale
call plug#end()


" base
set nocompatible                    " vim, not vi
syntax on                           " syntax highlighting
filetype plugin indent on           " recognise filetype, load plugins and indent files
set path+=**                        " search in dir of current file, cwd and subdirs

" interface
set cursorline                      " highlight current line
set number                          " show line numbers

" whitespace
set tabstop=4			            " number of spaces a tab counts for
set shiftwidth=4		            " number of spaces to use for each step of ident
set expandtab			            " insert spaces instead of tabs

" searching
set hlsearch                        " highlight search matches
set incsearch                       " search as you type

" backup and swap files
set nobackup                        " disable backup files
set noswapfile                      " disable swap files
set nowritebackup                   " disable auto bakcup before overwriting a file

" theme
syntax enable                       " syntax highlighting 
"let base16colorspace=256            " Access colors present in 256 colorspace
"colorscheme base16-solarized-light  " syntax colors

" ale
let g:ale_python_pylint_executable='pylint3'

" clang_complete
let s:uname = system("uname -s")
if s:uname == "Darwin\n"
    let g:clang_library_path='/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/libclang.dylib'
endif
