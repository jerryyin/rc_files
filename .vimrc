set autoindent
set smartindent
set cinoptions=(3
set shiftwidth=3
set softtabstop=3
set expandtab
set smarttab
""set ai
set clipboard=unnamed
""set colorcolumn=100
set autochdir

""eclim
""filetype plugin indent on
set guioptions-=m " turn off menu bar
set guioptions-=T " turn off toolbar
set guioptions-=L " turn off left scrollbar
set guioptions-=l
let g:EclimTempFilesEnable=0

"spelling
"not sure how this part interact with code
""set nospell
autocmd BufRead,BufNewFile *.tex setlocal spell
autocmd BufRead,BufNewFile *.tex setlocal spell spelllang=en_us
autocmd FileType gitcommit setlocal spell
autocmd FileType gitcommit setlocal spell spelllang=en_us
"languagetooll
set nocompatible
filetype plugin on
let g:languagetool_jar='$HOME/.vim/LanguageTool-2.7/languagetool-commandline.jar'

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
"set scrolloff=3
"set scrolloff=999
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
""map <C-F12>:!ctags -R --c++-kinds=+p --fields=+iaS --extra=+q .<CR>
"" find /d/perforce/ \( -name "*.h" -or -name "*.cpp" \) \( -not -path "*/development/**" -and -not -path "*/dev/**" \) >tags.files
"" ctags -R --c++-kinds=+p --fields=+ias --extra=+q -L tags.files
 set tags=./tags,tags;$HOME

""taglist
let Tlist_Show_One_File=1
let Tlist_Exit_OnlyWindow=1
nnoremap<silent><F8> : TlistToggle<CR>

""cscope
cs add /d/perforce/cscope.out /d/perforce/
set cscopequickfix=s-,c+,d-,i-,t-,e-
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
