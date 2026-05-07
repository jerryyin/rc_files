" General settings
set nocompatible                " Vim defaults rather than vi ones. Keep at top.
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
call plug#begin('~/.vim/plugged')
" gruvbox color scheme
Plug 'sainnhe/gruvbox-material'
" Syntax highlighting
Plug 'sheerun/vim-polyglot'

" Display
Plug 'preservim/nerdtree'
Plug 'edkolev/tmuxline.vim'
Plug 'wellle/context.vim'

" diff plugin
Plug 'mhinz/vim-signify'
" Show marks
Plug 'kshenoy/vim-signature'
" Improve status bar
Plug 'itchyny/lightline.vim'

" Color terminal: Ansi escape sequences
Plug 'Makaze/AnsiEsc'
" Startup window and session management
Plug 'mhinz/vim-startify'
" Auto resize split
"Plug 'camspiers/lens.vim'
Plug 'simeji/winresizer'
" Toggle line number
Plug 'jeffkreeftmeijer/vim-numbertoggle'
" Better folding
Plug 'pseewald/vim-anyfold'
" Indent guides line
Plug 'nathanaelkane/vim-indent-guides'

" Utility
" Auto inserts or deletes bracket, parens, quotes in pair
Plug 'jiangmiao/auto-pairs'
" Convert the line to comment
Plug 'tomtom/tcomment_vim'
" Function list, file fuzzy match
Plug 'Yggdroot/LeaderF', {'do': './install.sh'}
" Integrate with git
Plug 'tpope/vim-fugitive'
" MRU buffer
Plug 'jerryyin/vim-bufmru'
" Dispath async support
Plug 'tpope/vim-dispatch'
" Grep async support
Plug 'mhinz/vim-grepper'
" Test suport
Plug 'jerryyin/vim-mlirtools'
" File switch between cpp and header
Plug 'ericcurtin/CurtineIncSw.vim'
" A Vim plugin to copy text through SSH with OSC52
Plug 'ojroques/vim-oscyank', {'branch': 'main'}
" Add more text objects to vim
Plug 'wellle/targets.vim'
" pop up menu for insert mode completion
" This interfere with copilot
Plug 'AndrewRadev/splitjoin.vim'
" Insert mode shortcut
Plug 'tpope/vim-rsi'
" Surround text object
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
" Markdown syntax highlighting
Plug 'vim-pandoc/vim-pandoc-syntax'
" Auto save
Plug '907th/vim-auto-save'
" Path navigation
Plug 'tpope/vim-apathy'
" UNIX shell commands
Plug 'tpope/vim-eunuch'
" Make vim follow symlink
Plug 'aymericbeaumet/vim-symlink'
Plug 'github/copilot.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'liuchengxu/vista.vim'

" Tags
Plug 'ludovicchabant/vim-gutentags'

" Code formating
Plug 'vim-autoformat/vim-autoformat'
Plug 'llvm/llvm.vim'
call plug#end()

function! s:SourceConfig(name) abort
  execute 'source' fnameescape(expand('~/.vim/config/' . a:name . '.vim'))
endfunction

call s:SourceConfig('theme')
call s:SourceConfig('ui')
call s:SourceConfig('project')
call s:SourceConfig('tools')
