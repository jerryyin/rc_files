set tabstop=2
set autoindent
"" Doesn't work well with python
""set smartindent
set cinoptions=(2
set shiftwidth=4
set softtabstop=2
filetype indent on
filetype plugin on
set shiftwidth=2
set expandtab
set smarttab
"" It hides buffers instead of closing them. This means that you can have unwritten changes
"" to a file and open a new file using :e, without being forced to write or undo your changes first.
set hidden
""set ai
set clipboard=unnamed
""set colorcolumn=100
set autochdir
""Auto reload file on disk
set autoread | au CursorHold * checktime | call feedkeys("lh")

""Eliminating delays on ESC in vim and zsh
set timeoutlen=1000 ttimeoutlen=0

"Vundle plugin manager
"Plugin 'lvuts/vim-rtags'

"spelling
"not sure how this part interact with code
""set nospell
""autocmd BufRead,BufNewFile *.tex setlocal spell
""autocmd BufRead,BufNewFile *.tex setlocal spell spelllang=en_us
autocmd FileType gitcommit setlocal spell
autocmd FileType gitcommit setlocal spell spelllang=en_us

"might be a conflict with existing scheme"
syntax on
"does not look good"
set t_Co=256
""colorscheme elflord
""highlight Normal guifg=#bfca1d
""set background=dark
set mouse=a
""hi LineNr ctermfg=grey
colorscheme ir_black
set showmode
set showcmd
set cursorline
""set cursorcolumn
set ruler

set hlsearch
set ignorecase
set smartcase
set incsearch
set showmatch
nmap <space> i_<esc>r
""hi Search ctermbg=gray
execute "set scroll=" . winheight('.') / 3
set backspace=indent,eol,start

""ctags
map <C-F12>:!ctags -R --c++-kinds=+p --fields=+iaS --extra=+q .<CR>
set tags=./tags,tags;$HOME

""taglist
let Tlist_Show_One_File=1
let Tlist_Exit_OnlyWindow=1
nnoremap<silent><F8> : TlistToggle<CR>

""cscope
""set cscopequickfix=s-,c+,d-,i-,t-,e-

""mini buffer explorer
let g:miniBufExplMapWindowNavVim = 1
let g:miniBufExplMapWindowNavArrows = 1
let g:miniBufExplForceSyntaxEnable = 1
let g:miniBufExplMapCTabSwitchBufs = 1
let g:miniBufExplModSelTarget = 1
let g:miniBufExplMoreThanOne=0

""overwrite '=' to astyle formatting
""-s3 indent=3, -xL break after logical, -xC100 column 100 max, -xp remove comment prefix,
""-J add one line bracket
""set equalprg=astyle\ -s3\ -xL\ -xC100\ -xp\ -J\ -m0\ -M100\ --style=google
""set equalprg=astyle\ -s3\ -xL\ -xC100\ -xp\ -J\ -m0\ -M100\ -pcHS\ --mode=c\ --style=ansi

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

" moving around
noremap <C-J> <C-W>j
noremap <C-K> <C-W>k
noremap <C-H> <C-W>h
noremap <C-L> <C-W>l

" Resizing windows
nnoremap <C-up> <C-W>+
nnoremap <C-down> <C-W>-
nnoremap <C-left> <C-W><
nnoremap <C-right> <C-W>>

"pdf
:command! -complete=file -nargs=1 Rpdf :r !pdftotext -nopgbrk <q-args> -
:command! -complete=file -nargs=1 Rpdf :r !pdftotext -nopgbrk <q-args> - |fmt -csw78

"closing brackets
:inoremap ( ()<Esc>:let leavechar=")"<CR>i
:inoremap { {}<Esc>:let leavechar="}"<CR>i
:inoremap " ""<Esc>:let leavechar="\""<CR>i
:inoremap /* /**/<Esc>:let leavechar="*/"<CR>i
:imap <C-l> <Esc>:exec "normal f" . leavechar<CR>a

"relative number move
set relativenumber
set number
""autocmd InsertEnter * :set number
""autocmd InsertLeave * :set relativenumber
"when lose focus, set absolute number
:au FocusLost * :set number
:au FocusGained * :set relativenumber
