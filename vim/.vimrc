" General settings
set nocompatible                " Vim defaults rather than vi ones. Keep at top.
set history=10000
filetype indent on
filetype plugin on
set clipboard=unnamed
syntax on                       " Enable syntax highlighting.
set wrap                        " Wrap long lines.
set display=lastline            " Show as much of the line as will fit.
set wildmenu                    " Better tab completion in the commandline.
set wildmode=list:longest,full  " List all matches and complete to the longest match.
set nrformats-=octal            " Remove octal support from 'nrformats'.
"set formatoptions+=ncroqj      " Control automatic formatting.
set linebreak                   " Wrap long lines and make text easier to read
set foldlevel=2
set shiftwidth=2 tabstop=2 expandtab
set softtabstop=-1              " Use shiftwidth for number of spaces edit
set encoding=utf-8

" Apply indentation of current line to next
set autoindent
" Autoindent must be on, react to syntax/style of code
set smartindent
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

""Auto reload file on disk
set autoread

" It hides buffers instead of closing them. This means that you can have unwritten changes
" to a file and open a new file using :e, without being forced to write or undo your changes first.
set hidden

" Eliminating delays on ESC in vim and zsh
set timeoutlen=1000 ttimeoutlen=0

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

" Source the termdebug plugin
packadd termdebug

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
Plug 'morhetz/gruvbox'
" Syntax highlighting
Plug 'Valloric/vim-operator-highlight'
Plug 'sheerun/vim-polyglot'

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
Plug 'simeji/winresizer'
" Toggle line number
Plug 'jeffkreeftmeijer/vim-numbertoggle'
" Better folding
Plug 'pseewald/vim-anyfold'
" Smooth scrolling
Plug 'psliwka/vim-smoothie'
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
Plug 'mildred/vim-bufmru'
" Dispath async support
Plug 'tpope/vim-dispatch'
" Grep async support
Plug 'mhinz/vim-grepper'
" File switch between cpp and header
Plug 'ericcurtin/CurtineIncSw.vim'
" System clipboard support
" OSX - pbcopy and pbpaste
" Windows - clip and paste
" Linux - xsel
Plug 'christoomey/vim-system-copy'
" Add more text objects to vim
Plug 'wellle/targets.vim'
" pop up menu for insert mode completion
Plug 'skywind3000/vim-auto-popmenu'
Plug 'AndrewRadev/splitjoin.vim'
" Insert mode shortcut
Plug 'tpope/vim-rsi'
" Surround text object
Plug 'tpope/vim-surround'
" wiki
Plug 'vimwiki/vimwiki'
Plug 'jerryyin/vimwiki-sync'
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

" Tags
Plug 'ludovicchabant/vim-gutentags'

" Code formating
Plug 'Chiel92/vim-autoformat'
" Help correctly indent file in edit mode
Plug 'google/styleguide', { 'do': 'mkdir -p after/indent; cp -f *.vim after/indent/python.vim' }
Plug 'vim-scripts/google.vim', { 'do': 'mkdir -p after/indent; cp -f indent/*.vim after/indent/cpp.vim' }
Plug 'https://gist.github.com/jerryyin/ac01c9f2471446927d290f28cd9e2608.git',
    \ { 'as': 'vim-mlir-syntax', 'do': 'mkdir -p after/syntax; cp -f *.vim after/syntax/; rm *.vim' }
Plug 'https://gist.github.com/jerryyin/8e3119e35aaeed0b09cea43bfba04a32.git',
    \ { 'as': 'vim-mlir-indent', 'do': 'mkdir -p indent; cp -f *.vim indent/; rm *.vim' }
call plug#end()

" This is only necessary if you use "set termguicolors" in tmux
set background=dark
"let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
"let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
"set termguicolors
let g:gruvbox_contrast_dark = 'hard'
let g:gruvbox_contrast_light = 'hard'
let g:gruvbox_bold = 0
silent! colorscheme gruvbox
highlight String guifg=#b16286 ctermfg=132
highlight Normal ctermbg=None
let g:ophigh_color_gui = "#458588"
let g:ophigh_color = 66

" Color Scheme settings from vim cpp enhanced highlight plugin
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1

" Output the current syntax group
nnoremap <f12> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<cr>

" Folding
augroup anyfold
  autocmd!
  autocmd Filetype * if &ft == 'cpp' | AnyFoldActivate
augroup END

" disable anyfold for large files
augroup checkFileSize
  autocmd!
  let g:LargeFile = 1000000 " file is large if size greater than 1MB
  autocmd BufReadPre,BufRead * let f=getfsize(expand("<afile>")) | if f > g:LargeFile || f == -2 | call LargeFile() | endif
augroup END

function! LargeFile()
  augroup anyfold
    autocmd!
    autocmd Filetype * setlocal foldmethod=indent
  augroup END
endfunction

" Coding styles
" shiftwidth: >> indent; tabstop: how long a tab is
augroup ft
  autocmd!
  " Can enable filetype specific settings
  "autocmd FileType cpp    set shiftwidth=2 tabstop=2 expandtab
  autocmd FileType qf setlocal wrap
  autocmd BufNewFile,BufRead *.mlir set syntax=mlir
  autocmd FileType mlir setlocal comments+=://
augroup END

" Auto-pair
let g:AutoPairsFlyMode = 0

" Lens
let g:lens#width_resize_max = 85

" winresizer
let g:winresizer_start_key = '<C-t>'
let g:winresizer_finish_with_escape = 1

" Dispatch, disallow tmux pane capture trick
set shellpipe=2>&1\|tee
let g:dispatch_no_maps = 1

"indent guides
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_start_level = 3

" cscope settings
" The following maps all invoke one of the following cscope search types:
"
"   'f'   file:     open the filename under cursor
"   's'   symbol:   find this C symbol
"   'c'   calls:    find all calls to the function name under cursor
"   'i'   includes: find files that #include the filename under cursor
"   'a'   assign:   find places where this symbol is assigned a value
"   Refer to
"   https://stackoverflow.com/questions/24510721/cscope-result-handling-with-quickfix-window
set cscopequickfix=s-,c-,i-,a-
nmap <C-\>f :cs find f <C-R>=expand("<cword>")<CR><CR>
" Load following results into quickfix
nnoremap <C-\>s yiw:cs find s <C-R>=expand("<cword>")<CR><CR>:cwindow<CR>/<C-R>0<CR>
nnoremap <C-\>c yiw:cs find c <C-R>=expand("<cword>")<CR><CR>:cwindow<CR>/<C-R>0<CR>
nnoremap <C-\>i yiw:cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>:cwindow<CR>/<C-R>0<CR>
nnoremap <C-\>a yiw:cs find a <C-R>=expand("<cword>")<CR><CR>:cwindow<CR>/<C-R>0<CR>

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

" auto-format plugin (remap =)
" https://github.com/Chiel92/vim-autoformat/issues/192#issuecomment-316621090
" Do not enable auto format on save
vmap = :Autoformat<CR>
nmap =G :.,$Autoformat<CR>
nmap == :.Autoformat<CR>
nmap =% v%:Autoformat<CR>
nmap = :.-1,.Autoformat<CR>
nmap = :.,.+1Autoformat<CR>
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
let g:Lf_ShowDevIcons = 0
let g:Lf_HideHelp = 1
let g:Lf_StlColorscheme = 'powerline'
let g:Lf_PreviewResult = {'Function':0, 'BufTag':0}

" Fugitive
augroup fuDeleteBuffer
  autocmd!
  autocmd BufReadPost fugitive://* set bufhidden=delete
augroup END
" Set Gstatus to fixed length
nmap <leader>s :Git<CR>:15wincmd_<CR>
nmap <leader>d :Gvdiffsplit<CR>

" Vineagar/netrw enable relative line number
let g:netrw_bufsettings="noma nomod nonu nobl nowrap ro rnu"

" Grepper
let g:grepper = {}
let g:grepper.tools = ['ag', 'git', 'grep']
let g:grepper.dir = 'repo'
let g:grepper.highlight = 1
let g:grepper.prompt_mapping_tool = '<leader>g'
runtime plugin/grepper.vim
let g:grepper.ag.grepprg .= ' --ignore-dir build'
nnoremap <leader>ga :Grepper -tool ag<cr>
nnoremap <leader>gg :Grepper -tool git -cword -noprompt<cr>
nnoremap <leader>gs :Grepper -tool ag -cword -noprompt<cr>

" Airline
let g:airline_extensions = ['branch','tabline','gutentags','fugitiveline','grepper','netrw']
" Can add width. Potentially, %3l, %2c, %2p.
let g:airline_section_z = 'LN %l:%c %p%%'
let g:airline_highlighting_cache = 1
let g:airline#extensions#tabline#show_buffers = 1
let g:airline#extensions#tabline#show_tabs = 0
let g:airline#extensions#tabline#show_tab_type = 0
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'
" Use <ctrl>-e (instead of <ctrl>-<shift>-6) for buffer transition
noremap <C-e> <C-^>

" vim-auto-popmenu
" enable this plugin for filetypes, '*' for all files.
let g:apc_enable_ft = {'*':1 }
" source for dictionary, current or other loaded buffers, see ':help cpt'
set cpt=.,u,w,b
" don't select the first item.
set completeopt=menu,menuone,noselect

" vimwiki
nmap <Nop> <Plug>VimwikiRemoveHeaderLevel
let g:vimwiki_list = [{'path': '~/Documents/notes',
      \ 'syntax' : 'markdown',
      \ 'auto_tags' : 1,
      \ 'ext' : '.md'}]
let g:vimwiki_global_ext = 0
let g:vimwiki_filetypes = ['markdown', 'pandoc']
augroup vimwikigroup
  autocmd!
  " automatically update links on read diary
  autocmd BufRead,BufNewFile diary.md VimwikiDiaryGenerateLinks
  au! BufNewFile,BufFilePre,BufRead *.md set filetype=markdown.pandoc
  autocmd BufReadPost *.md set bufhidden=delete
augroup end
let g:pandoc#syntax#conceal#urls = 1
nmap <leader><space> <Plug>VimwikiToggleListItem

" CurtineIncSw
nmap <silent> <Leader>a :call CurtineIncSw()<cr>

" Auto save
let g:auto_save = 1

" Automatically deletes least recently used buffer
" A combination of https://www.vim.org/scripts/script.php?script_id=2346
" and
" https://vi.stackexchange.com/questions/2193/automatically-close-oldest-buffers
let g:nb_buffers_to_keep = 36

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
