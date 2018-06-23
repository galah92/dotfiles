" install vim-plug if need to
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" set vim-plug plugins
call plug#begin('~/.vim/plugged')
Plug 'w0rp/ale'                         " linting
call plug#end()

" interface
set number                              " print the line number in front of each line
syntax enable                           " syntax highlighting
colorscheme desert

" whitespace
set tabstop=4                           " number of spaces that a <Tab> in the file counts for
set shiftwidth=4                        " number of spaces to use for each step of (auto) ident
set expandtab                           " use the appropriate number of spaces to insert a <Tab>
