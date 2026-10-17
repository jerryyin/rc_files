call plug#begin('~/.vim/plugged')
" gruvbox color scheme
Plug 'sainnhe/gruvbox-material'
" Syntax highlighting
" Native Windows uses Vim syntax plus CoC/clangd semantic tokens. Polyglot's
" unnamed-buffer detection currently fails there; keep it for Linux as before.
if !has('win32')
  Plug 'sheerun/vim-polyglot'
endif

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
if has('win32')
  Plug 'Yggdroot/LeaderF'
else
  Plug 'Yggdroot/LeaderF', {'do': './install.sh'}
endif
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
if !has('win32')
  Plug 'ludovicchabant/vim-gutentags'
endif

" Code formating
Plug 'vim-autoformat/vim-autoformat'
Plug 'llvm/llvm.vim'
call plug#end()

" Shared extension choices used by both Vim and the Windows bootstrap.
let g:coc_global_extensions = ['coc-tsserver', 'coc-json', 'coc-pyright', 'coc-snippets']
