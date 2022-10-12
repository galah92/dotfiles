set nocompatible

" https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
Plug 'arcticicestudio/nord-vim'
Plug 'sainnhe/gruvbox-material'
"Plug 'rust-lang/rust.vim'
Plug 'vim-syntastic/syntastic'
Plug 'github/copilot.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
call plug#end()

set cursorline
set termguicolors

let g:nord_cursor_line_number_background = 1
let g:nord_uniform_status_lines = 1
let g:nord_bold_vertical_split_line = 1
colorscheme nord

set nobackup
set number
set relativenumber
set expandtab
set tabstop=4
set shiftwidth=4
set splitright " as default
set splitbelow " as default
set wildmenu " show search results menu

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 0
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

let g:coc_global_extensions = ['coc-tsserver']
