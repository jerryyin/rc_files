" General settings
set nocompatible                " Vim defaults rather than vi ones. Keep at top.
filetype indent on
filetype plugin on
set clipboard=unnamed
syntax on                       " Enable syntax highlighting.
set wrap                        " Wrap long lines.
set laststatus=2                " Always show the statusline.
set ruler                       " Show the ruler in the statusline.
set display=lastline            " Show as much of the line as will fit.
set wildmenu                    " Better tab completion in the commandline.
set wildmode=list:longest,full  " List all matches and complete to the longest match.
set nrformats-=octal            " Remove octal support from 'nrformats'.
"set formatoptions+=ncroqj      " Control automatic formatting.
set linebreak                   " Wrap long lines and make text easier to read
set foldlevel=2

" Coding styles
" shiftwidth: >> indent; tabstop: how long a tab is
augroup ft
  autocmd!
  autocmd FileType python set shiftwidth=2 tabstop=2 expandtab
  autocmd FileType cpp    set shiftwidth=2 tabstop=2 expandtab
  autocmd BufNewFile,BufRead *.mlir set syntax=mlir
augroup END

" Folding
augroup anyfold
  autocmd!
  autocmd FileType * AnyFoldActivate
augroup END

" disable anyfold for large files
let g:LargeFile = 1000000 " file is large if size greater than 1MB
autocmd BufReadPre,BufRead * let f=getfsize(expand("<afile>")) | if f > g:LargeFile || f == -2 | call LargeFile() | endif
function LargeFile()
  augroup anyfold
    autocmd!
    autocmd Filetype * setlocal foldmethod=indent
  augroup END
endfunction

" Apply indentation of current line to next
set autoindent
" Autoindent must be on, react to syntax/style of code
set smartindent
" Don't use the tab character
set smarttab

" Cursor and mouse
set mouse=a
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

""Auto reload file on disk
set autoread

" It hides buffers instead of closing them. This means that you can have unwritten changes
" to a file and open a new file using :e, without being forced to write or undo your changes first.
set hidden

" Eliminating delays on ESC in vim and zsh
set timeoutlen=1000 ttimeoutlen=0

" Scroll 1/3 of the screen height
execute "set scroll=" . winheight('.') / 3

" Relative number move
set number relativenumber

" Moving around with ctrl + jkhl
noremap <C-J> <C-W>j
noremap <C-K> <C-W>k
noremap <C-H> <C-W>h
noremap <C-L> <C-W>l
tnoremap <C-J> <C-W>j
tnoremap <C-K> <C-W>k
tnoremap <C-H> <C-W>h
tnoremap <C-L> <C-W>l
tnoremap <Esc> <C-\><C-N>

" vim-plug plugin manager
call plug#begin('~/.vim/plugged')
" gruvbox color scheme
Plug 'morhetz/gruvbox'
" Syntax highlighting
Plug 'octol/vim-cpp-enhanced-highlight', { 'for': ['c', 'cpp'] }
" llvm plugin
Plug 'rhysd/vim-llvm', { 'for': 'llvm' }

" Display
" Project drawer directory browser
Plug 'tpope/vim-vinegar'
" diff plugin
Plug 'mhinz/vim-signify'
" Show marks
Plug 'kshenoy/vim-signature'
" Improve status bar
" Plug 'itchyny/lightline.vim'
Plug 'vim-airline/vim-airline'
" Color terminal: Ansi escape sequences
Plug 'powerman/vim-plugin-AnsiEsc'
" Startup window and session management
Plug 'mhinz/vim-startify'
" Auto resize split
Plug 'camspiers/lens.vim'
Plug 'roxma/vim-window-resize-easy'
" Toggle line number
Plug 'jeffkreeftmeijer/vim-numbertoggle'
" Better folding
Plug 'pseewald/vim-anyfold'

" Utility
" Auto inserts or deletes bracket, parens, quotes in pair
Plug 'jiangmiao/auto-pairs'
" Convert the line to comment
Plug 'tomtom/tcomment_vim'
" Function list, file fuzzy match
Plug 'Yggdroot/LeaderF', {'do': './install.sh'}
" Integrate with git
Plug 'tpope/vim-fugitive'
" Insert mode completions
Plug 'ervandew/supertab'
" MRU buffer
Plug 'mildred/vim-bufmru'
" Dispath async support
Plug 'tpope/vim-dispatch'
" Grep async support
Plug 'mhinz/vim-grepper'
" File switch between cpp and header
Plug 'derekwyatt/vim-fswitch'
" System clipboard support
" OSX - pbcopy and pbpaste
" Windows - clip and paste
" Linux - xsel
Plug 'christoomey/vim-system-copy'
" Add more text objects to vim
Plug 'wellle/targets.vim'

" Tags
Plug 'ludovicchabant/vim-gutentags'

" Code formating
Plug 'Chiel92/vim-autoformat'
" Help correctly indent file in edit mode
Plug 'google/styleguide', { 'do': 'mkdir -p after/indent; cp -f *.vim after/indent/python.vim' }
Plug 'vim-scripts/google.vim', { 'do': 'mkdir -p after/indent; cp -f indent/*.vim after/indent/cpp.vim' }
Plug 'https://gist.github.com/jerryyin/ac01c9f2471446927d290f28cd9e2608.git',
    \ { 'as': 'vim-mlir', 'do': 'mkdir -p after/syntax; cp -f *.vim after/syntax/' }
call plug#end()

" This is only necessary if you use "set termguicolors" in tmux
set background=dark
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
set termguicolors
let g:gruvbox_contrast_dark = 'hard'
let g:gruvbox_contrast_light = 'hard'
silent! colorscheme gruvbox
hi String guifg=#b16286

" Color Scheme settings from vim cpp enhanced highlight plugin
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1

" Output the current syntax group
nnoremap <f10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<cr>

" Auto-pair
let g:AutoPairsFlyMode = 0

" Lens
let g:lens#width_resize_max = 85

" Dispatch, disallow tmux pane capture trick
set shellpipe=2>&1\|tee
let g:dispatch_no_maps = 1

" cscope settings
" The following maps all invoke one of the following cscope search types:
"
"   's'   symbol: find all references to the token under cursor
"   'g'   global: find global definition(s) of the token under cursor
"   'c'   calls:  find all calls to the function name under cursor
"   't'   text:   find all instances of the text under cursor
"   'e'   egrep:  egrep search for the word under cursor
"   'f'   file:   open the filename under cursor
"   'i'   includes: find files that include the filename under cursor
"   'd'   called: find functions that function under cursor calls
nmap <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
nmap <C-\>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
nmap <C-\>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
nmap <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>

" gutentags settings
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
" Project root directory will be used as the prefix to construct an absolute path.
set csre

" auto-format plugin
" Disable auto format on save
noremap <silent> == V:Autoformat<CR>
" Disable fallback to vim's indent file, only remove trailing whitespace
let g:autoformat_autoindent = 0
let g:autoformat_retab = 0

" LeaderF
" By default enabled: Global search files and tags
"noremap <leader>f :LeaderFile<cr>
"noremap <leader>b :LeaderBuffer<cr>
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

" Fugitive
augroup fuDeleteBuffer
  autocmd!
  autocmd BufReadPost fugitive://* set bufhidden=delete
augroup END

" Grepper
let g:grepper = {}
let g:grepper.dir = 'repo'
let g:grepper.highlight = 1
nnoremap <leader>g :Grepper<cr>

" Airline
let g:airline_extensions = ['branch','tabline','gutentags','fugitiveline','grepper','netrw']
let g:airline_highlighting_cache = 1
let g:airline#extensions#tabline#show_buffers = 1
let g:airline#extensions#tabline#show_tabs = 0
let g:airline#extensions#tabline#show_tab_type = 0
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'
" Use <ctrl>-e (instead of <ctrl>-<shift>-6) for buffer transition
noremap <C-e> <C-^>

" FSwitch
augroup fswitch
  autocmd!
  autocmd BufEnter *.cc let b:fswitchdst = 'hpp,h'
  autocmd BufEnter *.cpp let b:fswitchdst = 'h,hpp'
  autocmd BufEnter *.h let b:fswitchdst = 'cpp,cc'
  " MLIR Dialect specific re
  autocmd BufEnter *.h let b:fswitchlocs = 'reg:|include/mlir|lib|'
  autocmd BufEnter *.cpp let b:fswitchlocs = 'reg:|lib|include/mlir|'
augroup END
nmap <silent> <Leader>of :FSHere<cr>

" Automatically deletes least recently used buffer
" A combination of https://www.vim.org/scripts/script.php?script_id=2346
" and
" https://vi.stackexchange.com/questions/2193/automatically-close-oldest-buffers
let g:nb_buffers_to_keep = 12

function! s:Close(nb_to_keep)
  "" If the lenth of buffer list is small, return early
  let bufmru_bnrs = BufMRUList()
  if a:nb_to_keep >= len(bufmru_bnrs)
    return
  endif
  let nb_to_strip = len(bufmru_bnrs) - a:nb_to_keep
  " The newly opened one is ranked last, remove it
  let buflru_bnrs = reverse(copy(bufmru_bnrs[0:-2]))
  " May need to filter out modified buffers
  " Right now will error out and not delete modified buffer
  "filter(buflru_bnrs, 'buflisted(v:val) && !getbufvar(v:val, "&modified")')
  let buffers_to_strip = buflru_bnrs[0:(nb_to_strip-1)]
  exe 'bw '.join(buffers_to_strip, ' ')
endfunction

" Manually
"command! -nargs=1 CloseOldBuffers call s:Close(<args>)
" Automatically
augroup closeOldBuffers
  autocmd!
  autocmd BufNew * call s:Close(g:nb_buffers_to_keep)
augroup END
