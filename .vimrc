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
nnoremap <C-J> <C-W>j
nnoremap <C-K> <C-W>k
nnoremap <C-H> <C-W>h
nnoremap <C-L> <C-W>l

" Resizing windows with ctrl + direction
nnoremap <C-Up> <C-W>+
nnoremap <C-Down> <C-W>-
nnoremap <C-Left> <C-W><
nnoremap <C-Right> <C-W>>

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
" Code formating tool
Plug 'rhysd/vim-clang-format'
" llvm plugin
Plug 'rhysd/vim-llvm'
" diff plugin
Plug 'mhinz/vim-signify'
" Function list, file fuzzy match
Plug 'Yggdroot/LeaderF', {'do': './install.sh'}
" Convert the line to comment
Plug 'tomtom/tcomment_vim'
" Improve status bar
Plug 'itchyny/lightline.vim'
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
hi CursorLineNr guifg=NONE    guibg=#121212  gui=NONE      ctermfg=NONE       ctermbg=NONE        cterm=NONE
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

" vim clang format plugin
let g:clang_format#detect_style_file = 1
" Aggressively re-formatting, alternative: autocmd FileType c,cc,cpp,objc ClangFormatAutoEnable
let g:clang_format#auto_format_on_insert_leave = 1
let g:clang_format#auto_formatexpr = 1

" LeaderF
" By default enabled: Global search files and tags
"noremap <leader>f :LeaderFile<cr>
noremap <leader>t :LeaderfTag<cr>
" Search functions in oened buffer
noremap <leader>i :LeaderfFunction!<cr>
let g:Lf_StlSeparator = { 'left': '', 'right': '', 'font': '' }

let g:Lf_RootMarkers = ['.project', '.root', '.svn', '.git']
let g:Lf_WorkingDirectoryMode = 'Ac'
let g:Lf_WindowHeight = 0.30
let g:Lf_CacheDirectory = $HOME
let g:Lf_ShowRelativePath = 0
let g:Lf_HideHelp = 1
let g:Lf_StlColorscheme = 'powerline'
let g:Lf_PreviewResult = {'Function':0, 'BufTag':0}
