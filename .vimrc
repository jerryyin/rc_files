" General settings
filetype indent on
filetype plugin on
set autochdir
set clipboard=unnamed

" Coding styles
" Apply indentation of current line to next
set autoindent
" Autoindent must be on, react to syntax/style of code
set smartindent
" Don't use the tab character
set expandtab
set smarttab
" Determines how long a tab appear to be
set tabstop=2
" Stricter rules for C
set cindent
set cinoptions=(2
" Indentation via >> will indent 2 characters
set shiftwidth=2

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

" Moving around with ctrl + jkhl
noremap <C-J> <C-W>j
noremap <C-K> <C-W>k
noremap <C-H> <C-W>h
noremap <C-L> <C-W>l

" Resizing windows with ctrl + direction
nnoremap <C-up> <C-W>+
nnoremap <C-down> <C-W>-
nnoremap <C-left> <C-W><
nnoremap <C-right> <C-W>>

" vim-plug plugin manager
call plug#begin('~/.vim/plugged')
" cscope key mappings
Plug 'dr-kino/cscope-maps'
Plug 'ludovicchabant/vim-gutentags'
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
" llvm plugin
Plug 'rhysd/vim-llvm'
call plug#end()

set t_Co=256
set background=dark
" Color Scheme settings from vim cpp enhanced highlight plugin
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_experimental_template_highlight = 1
" Below are lines picked from colorscheme ir_black
" For cterfg256 color refer to here: https://jonasjacek.github.io/colors/
" Or https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg
hi link markdownItalic Normal
hi CursorLine  guifg=NONE     guibg=#121212  gui=NONE      ctermfg=NONE       ctermbg=NONE        cterm=BOLD
hi Comment     guifg=#7C7C7C  guibg=NONE     gui=NONE      ctermfg=242        ctermbg=NONE        cterm=NONE
hi Search      guifg=NONE     guibg=#2F2F00  gui=underline ctermfg=NONE       ctermbg=NONE	      cterm=underline
hi VertSplit   guifg=#202020  guibg=#202020  gui=NONE      ctermfg=darkgray   ctermbg=darkgray    cterm=NONE
hi StatusLine  guifg=#CCCCCC  guibg=#202020  gui=italic    ctermfg=white      ctermbg=darkgray    cterm=NONE
hi StatusLineNC guifg=black   guibg=#202020  gui=NONE      ctermfg=blue       ctermbg=darkgray    cterm=NONE
hi LineNr      guifg=#3D3D3D  guibg=black    gui=NONE      ctermfg=darkgray   ctermbg=NONE        cterm=NONE
hi Statement   guifg=#6699CC  guibg=NONE     gui=NONE      ctermfg=33         ctermbg=NONE        cterm=NONE
hi Constant    guifg=#99CC99  guibg=NONE     gui=NONE      ctermfg=201        ctermbg=NONE        cterm=NONE
hi Identifier  guifg=#C6C5FE  guibg=NONE     gui=NONE      ctermfg=215        ctermbg=NONE        cterm=NONE

" Output the current syntax group
nnoremap <f10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<cr>

" NERDTree
nnoremap<silent><F8> : NERDTreeToggle<CR>

" gutentags settings
set cscoperelative
let g:gutentags_generate_on_new = 1
let g:gutentags_generate_on_missing = 1
let g:gutentags_generate_on_write = 1
let g:gutentags_generate_on_empty_buffer = 0
let g:gutentags_project_root = ['.root', '.svn', '.git', '.hg', '.project']
let g:gutentags_ctags_tagfile = '.tags'
let g:gutentags_modules = []
if executable('ctags')
    let g:gutentags_modules += ['ctags']
endif
if executable('gtags-cscope') && executable('gtags')
    let g:gutentags_modules += ['gtags_cscope']
endif

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

