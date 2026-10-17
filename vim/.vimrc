" General settings
set nocompatible                " Vim defaults rather than vi ones. Keep at top.
" Resolve the checkout even when this vimrc is reached through a stow symlink.
let s:vim_root = fnamemodify(resolve(expand('<sfile>:p')), ':h')
if has('win32')
  let g:coc_config_home = s:vim_root . '/.vim'
  execute 'source ' . fnameescape(s:vim_root . '/.vim/config/windows.vim')
endif
set history=10000
filetype indent on
filetype plugin on
set clipboard=unnamed
syntax on                       " Enable syntax highlighting
set wrap                        " Wrap long lines
set display=lastline            " Show as much of the line as will fit
set wildmenu                    " Better tab completion in the commandline
set wildmode=list:longest,full  " List all matches and complete to the longest match
set nrformats-=octal            " Remove octal support from 'nrformats'
" set formatoptions+=ncroqj     " Control automatic formatting
set linebreak                   " Wrap long lines and make text easier to read
set foldlevel=2
set shiftwidth=2 tabstop=2 expandtab
set softtabstop=-1              " Use shiftwidth for number of spaces edit
set encoding=utf-8

" Apply indentation of current line to next
set autoindent
" Filetype indent scripts handle language-specific indentation.
" Don't use the tab character
set smarttab

" Cursor and mouse
set mouse=a
set shortmess=a
set showmode
set showcmd
set cursorline
set ruler
set splitbelow
set splitright

" Search
set hlsearch
set ignorecase
set smartcase
set incsearch
set showmatch

" Make backspace behavior match normal editor
set backspace=indent,eol,start

" Auto reload file on disk
set autoread

" It hides buffers instead of closing them. This means that you can have unwritten changes
" to a file and open a new file using :e, without being forced to write or undo your changes first.
set hidden

" Eliminating delays on ESC in vim and zsh
set timeoutlen=1000 ttimeoutlen=0

" Relative number move
set number relativenumber

" polyglot: disable its indent engine as it kill performance
let g:polyglot_disabled = ['autoindent', 'sensible']

" Auto install vim-plug if it does not exist
if empty(glob('~/.vim/autoload/plug.vim'))
  silent execute "!curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  augroup vimPlug
    autocmd!
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  augroup END
endif

" vim-plug plugin manager
execute 'source ' . fnameescape(s:vim_root . '/.vim/config/plugins.vim')

function! s:SourceConfig(name) abort
  execute 'source ' . fnameescape(s:vim_root . '/.vim/config/' . a:name . '.vim')
endfunction

call s:SourceConfig('theme')
call s:SourceConfig('ui')
call s:SourceConfig('project')
call s:SourceConfig('tools')
