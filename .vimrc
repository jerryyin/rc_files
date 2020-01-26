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
Plug 'jsfaint/gen_tags.vim'
" mini buffer explorer
Plug 'fholgado/minibufexpl.vim'
" ir_black color theme
" Plug 'twerth/ir_black'
Plug 'octol/vim-cpp-enhanced-highlight'
" NERD tree navigator sidebar
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
" Auto inserts or deletes bracket, parens, quotes in pair
Plug 'jiangmiao/auto-pairs'
" Google code formating tool
Plug 'google/vim-maktaba'
Plug 'google/vim-codefmt'
" Configure codefmt's maktaba flags
Plug 'google/vim-glaive'
call plug#end()

set t_Co=256
set background=dark
" Color Scheme settings from vim cpp enhanced highlight plugin
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_experimental_template_highlight = 1
" Below are lines picked from colorscheme ir_black
" For cterfg256 color refer to here: https://jonasjacek.github.io/colors/
hi CursorLine  guifg=NONE     guibg=#121212  gui=NONE      ctermfg=NONE       ctermbg=NONE        cterm=BOLD
hi Comment     guifg=#7C7C7C  guibg=NONE     gui=NONE      ctermfg=242        ctermbg=NONE        cterm=NONE
hi Search      guifg=NONE     guibg=#2F2F00  gui=underline ctermfg=NONE       ctermbg=NONE	      cterm=underline
hi VertSplit   guifg=#202020  guibg=#202020  gui=NONE      ctermfg=darkgray   ctermbg=darkgray    cterm=NONE
hi StatusLine  guifg=#CCCCCC  guibg=#202020  gui=italic    ctermfg=white      ctermbg=darkgray    cterm=NONE
hi StatusLineNC guifg=black   guibg=#202020  gui=NONE      ctermfg=blue       ctermbg=darkgray    cterm=NONE
hi LineNr      guifg=#3D3D3D  guibg=black    gui=NONE      ctermfg=darkgray   ctermbg=NONE        cterm=NONE
hi Statement   guifg=#6699CC  guibg=NONE     gui=NONE      ctermfg=27         ctermbg=NONE        cterm=NONE
hi Constant    guifg=#99CC99  guibg=NONE     gui=NONE      ctermfg=201        ctermbg=NONE        cterm=NONE
hi Identifier  guifg=#C6C5FE  guibg=NONE     gui=NONE      ctermfg=215        ctermbg=NONE        cterm=NONE

" Output the current syntax group
nnoremap <f10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<cr>

" NERDTree
nnoremap<silent><F8> : NERDTreeToggle<CR>

let g:gen_tags#gtags_default_map = 1
"cscope
" set cscopequickfix=s-,c-,d-,i-,t-,e-
" Auto load cscope.out database
function! LoadCscope()
 "let db = findfile("cscope.out", ".;")
  let db = findfile("GTAGS", ".;")
  if (!empty(db))
   "let path = strpart(db, 0, match(db, "/cscope.out$"))
    let path = strpart(db, 0, match(db, "/GTAGS$"))
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

