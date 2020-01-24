" General settings
filetype indent on
filetype plugin on
set autochdir
set clipboard=unnamed

" Coding styles
set tabstop=2
set autoindent
set smartindent
set cinoptions=(2
set shiftwidth=4
set softtabstop=2
set shiftwidth=2
set expandtab
set smarttab

" Color scheme
"syntax on
"set colorcolumn=100
"hi LineNr ctermfg=grey
" Might be a conflict with existing scheme"
" Reduce the number of colors, but make backgroud visible
set t_Co=256
""highlight Normal guifg=#bfca1d
"set background=dark
""hi Search ctermbg=gray

" Cursor and mouse
set mouse=a
set showmode
set showcmd
set cursorline
set ruler

" Search
set hlsearch
set ignorecase
set smartcase
set incsearch
set showmatch
nmap <space> i_<esc>r

" Make backspace behavior match normal editor
set backspace=indent,eol,start

""Auto reload file on disk
set autoread | au CursorHold * checktime | call feedkeys("lh")

" It hides buffers instead of closing them. This means that you can have unwritten changes
" to a file and open a new file using :e, without being forced to write or undo your changes first.
set hidden

" Eliminating delays on ESC in vim and zsh
set timeoutlen=1000 ttimeoutlen=0

" Scroll 1/3 of the screen height
execute "set scroll=" . winheight('.') / 3

" ctags
set tags=./tags,tags;$HOME

" Relative number move
set relativenumber
set number

" When lose focus, set absolute number
:au FocusLost * :set number
:au FocusGained * :set relativenumber

" Moving around
noremap <C-J> <C-W>j
noremap <C-K> <C-W>k
noremap <C-H> <C-W>h
noremap <C-L> <C-W>l

" Resizing windows
nnoremap <C-up> <C-W>+
nnoremap <C-down> <C-W>-
nnoremap <C-left> <C-W><
nnoremap <C-right> <C-W>>

" vim-plug plugin manager
call plug#begin('~/.vim/plugged')
" cscope key mappings
Plug 'dr-kino/cscope-maps'
" mini buffer explorer
Plug 'fholgado/minibufexpl.vim'
" ir_black color theme
Plug 'twerth/ir_black'
" NERD tree navigator sidebar
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
" Google code formating tool
Plug 'google/vim-maktaba'
Plug 'google/vim-codefmt'
" Configure codefmt's maktaba flags
Plug 'google/vim-glaive'
call plug#end()

colorscheme ir_black

" NERDTree
nnoremap<silent><F8> : NERDTreeToggle<CR>

""cscope
set cscopequickfix=s-,c-,d-,i-,t-,e-
""Auto load cscope.out database
function! LoadCscope()
  let db = findfile("cscope.out", ".;")
  if (!empty(db))
    let path = strpart(db, 0, match(db, "/cscope.out$"))
    set nocscopeverbose " suppress 'duplicate connection' error
      exe "cs add " . db . " " . path
      set cscopeverbose
  endif
endfunction
au BufEnter /* call LoadCscope()

""au BufWrite * :call SetAuto()
au BufWrite * :%s/\s\+$//e
func! SetAuto()
   let l:winview = winsaveview()
   Autoformat
   "single line of ); increase indent"
   :silent %s/^);$\|^   \+);$/   &/e
   "single line of ) increase indent"
   :silent %s/^)$\|^   \+)$/   &/e
   "special case of reference on the second line, add indent
   /->\n\_.\{-});
   :silent let @a="gn=nn"
   :silent %normal @a
   :noh
   call winrestview(l:winview)
endfunction
noremap <F12> :call SetAuto()<CR>

