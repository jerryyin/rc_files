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

" Moving around with ctrl + jkhl
noremap <C-J> <C-W>j
noremap <C-K> <C-W>k
noremap <C-H> <C-W>h
noremap <C-L> <C-W>l
tnoremap <C-h> <c-\><C-n><C-w>h
tnoremap <C-j> <c-\><C-n><C-w>j
tnoremap <C-k> <c-\><C-n><C-w>k
tnoremap <C-l> <c-\><C-n><C-w>l
tnoremap <Esc> <C-\><C-N>
" Use <C-V> in terminal for paste
tnoremap <C-V> <C-W>""

cabbrev bterm bo term ++rows=15

" Split_number C-w C-w
" The panes are numbered from top-left to bottom-right with the
" first one getting the number 1.
" For switching to a particular pane, press <i> + <tab>
nnoremap <tab> <C-W><C-W>

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
" Auto decide indent amount
Plug 'tpope/vim-sleuth'

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
Plug 'jerryyin/vim-cmake'
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
Plug 'puremourning/vimspector'

" Tags
Plug 'ludovicchabant/vim-gutentags'

" Code formating
Plug 'vim-autoformat/vim-autoformat'
" Help correctly indent file in edit mode
Plug 'google/styleguide', { 'do': 'mkdir -p after/indent; cp -f *.vim after/indent/python.vim' }
Plug 'llvm/llvm.vim'
call plug#end()

set background=dark
if has("termguicolors") && $TERM =~ "256color" &&
  \ ($COLORTERM =~ "truecolor" || !empty($TMUX))
    " Terminal supports True Color
    set termguicolors
else
    " Fall back to 256 colors
    set notermguicolors
endif

set spell
" Undercurl
let &t_Cs = "\e[4:3m"
" Underdouble
let &t_Us = "\e[4:2m"
" Underdotted
let &t_ds = "\e[4:4m"
" Underdashed
let &t_Ds = "\e[4:5m"
" Reset
let &t_Ce = "\e[4:0m"

" This configuration option should be placed before `colorscheme gruvbox-material`.
" Available values: 'hard', 'medium'(default), 'soft'
let g:gruvbox_material_background = 'hard'
let g:gruvbox_material_ui_contrast = 'high'
let g:gruvbox_material_transparent_background = 2
let g:gruvbox_material_enable_bold = 1
let g:gruvbox_material_enable_italic = 1
let g:gruvbox_material_diagnostic_text_highlight = 1
" highlight error/warning/info hint lines
let g:gruvbox_material_diagnostic_virtual_text = 'colored'
let g:gruvbox_material_diagnostic_text_highlight = 1
" For better performance
let g:gruvbox_material_better_performance = 1
" Override Difftext as it becomes invisible when overlapping with cursorline
function! s:gruvbox_material_custom() abort
  " Initialize the color palette.
  " The first parameter is a valid value for `g:gruvbox_material_background`,
  " the second parameter is a valid value for `g:gruvbox_material_foreground`,
  " and the third parameter is a valid value for `g:gruvbox_material_colors_override`.
  let l:palette = gruvbox_material#get_palette('hard', 'material', {})
  " Define a highlight group.
  " The first parameter is the name of a highlight group,
  " the second parameter is the foreground color,
  " the third parameter is the background color,
  " the fourth parameter is for UI highlighting which is optional,
  " and the last parameter is for `guisp` which is also optional.
  " See `autoload/gruvbox_material.vim` for the format of `l:palette`.
  call gruvbox_material#highlight('DiffText', l:palette.red, l:palette.yellow, 'bold')
  call gruvbox_material#highlight('String', l:palette.purple, l:palette.none)
  " CocCommand semanticTokens.inspect
  call gruvbox_material#highlight('CocSemTypeProperty', l:palette.aqua, l:palette.none,'underline')
endfunction

augroup GruvboxMaterialCustom
  autocmd!
  autocmd ColorScheme gruvbox-material call s:gruvbox_material_custom()
augroup END
colorscheme gruvbox-material

" Context.vim
let g:context_highlight_tag = '<hide>'
" Context.vim will override <C-e>, undo it by resetting control variable
let g:context_add_mappings = 0

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
  autocmd BufNewFile,BufRead *.mlir set filetype=mlir
  autocmd BufNewFile,BufRead *.cu set filetype=cuda
  autocmd BufNewFile,BufRead *.dockerfile set filetype=dockerfile
  autocmd FileType mlir setlocal comments+=://
augroup END

" Auto-pair
let g:AutoPairsFlyMode = 0

" Lens
let g:lens#width_resize_max = 85

" winresizer
let g:winresizer_start_key = '<C-t>'
let g:winresizer_finish_with_escape = 1

" lightline
" Customize colorscheme, branch and tabline
set showtabline=2
let g:lightline = {
  \ 'colorscheme': 'gruvbox_material',
  \ 'active': {
  \   'left': [['mode', 'paste'],
  \            ['gitbranch', 'readonly', 'filename', 'modified']]
  \ },
  \ 'component_function': {
  \   'gitbranch': 'FugitiveHead'
  \ },
  \ 'tabline': {
  \   'left': [ [ 'mrubuffers' ] ],
  \   'right': [ [ 'tabnum' ] ]
  \ },
  \ 'tabline_subseparator': { 'left': '', 'right': ''  },
  \ 'component_expand': {
  \   'mrubuffers': 'bufmru#lightline#buffers',
  \   'tabnum': 'bufmru#lightline#tabnum',
  \ },
  \ 'component_type': {
  \   'buffers':       'tabsel',
  \   'mrubuffers':    'tabsel',
  \ },
  \ 'component_raw': {
  \   'mrubuffers':     1,
  \   'tabnum':         1,
  \ },
  \ 'enable': {
  \   'statusline': 1,
  \   'tabline': 1
  \ }
\ }

" Dispatch, disallow tmux pane capture trick
set shellpipe=2>&1\|tee
let g:dispatch_no_maps = 1
nnoremap <leader>qo :Copen<CR>:10wincmd_<CR>
nnoremap <leader>qc :cclose<CR>

nnoremap <leader>bb :CMakeBuild<CR>
nnoremap <leader>bc :CMakeBuild --target clean<CR>
" IREE specific setup, do ROCm build
nnoremap <leader>bp :CMakeConfigure --preset rocm -Wno-dev<CR>
nnoremap <leader>tf :CMakeTest -R %:t --output-on-failure -E 'cuda\|metal\|vulkan\|cpu\|e2e'<CR>
nnoremap <leader>ta :CMakeTest all -j32 --output-on-failure -E 'cuda\|metal\|vulkan\|cpu\|e2e'<CR>

" Do not allow auto-resize of quickfix window
let g:lens#disabled_filetypes = ['qf, fugitive', 'termdebug', '']
augroup QuickfixCustomSettings
  autocmd!
  " Apply AnsiEsc when buffer is loaded, one time setup
  autocmd BufRead * if &filetype == 'qf' | execute 'AnsiEsc' | endif
augroup END
let g:ansi_Black = '#1d2021'
let g:ansi_DarkRed = '#cc241d'
let g:ansi_DarkGreen = '#98971a'
let g:ansi_DarkYellow = '#d79921'
let g:ansi_DarkBlue = '#458588'
let g:ansi_DarkMagenta = '#b16286'
let g:ansi_DarkCyan = '#689d6a'
let g:ansi_LightGray = '#ebdbb2'
let g:ansi_DarkGray = '#a89984'
" Escape sequence for Ansi
nnoremap <leader>ea :AnsiEsc<CR>

" Indent guides
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_start_level = 3
" Default value is 30, kills performance
let g:indent_guides_indent_levels = 8

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
let g:Lf_ShortcutF = '<leader>ff'
let g:Lf_ShortcutB = '<leader>fb'
let g:Lf_StlSeparator = { 'left': '', 'right': '', 'font': '' }
let g:Lf_RootMarkers = ['.project', '.root', '.svn', '.git']
let g:Lf_WorkingDirectoryMode = 'Ac'
let g:Lf_WindowHeight = 0.30
let g:Lf_CacheDirectory = $HOME
let g:Lf_ShowRelativePath = 0
let g:Lf_ShowDevIcons = 0
let g:Lf_HideHelp = 1
" Disable mru to prevent redundant file write in switching buffers
let g:Lf_MruEnable = 0
let g:Lf_StlColorscheme = 'powerline'
let g:Lf_PreviewResult = {'Function':0, 'BufTag':0}
let g:Lf_WindowPosition = 'popup'

" Fugitive
augroup fuDeleteBuffer
  autocmd!
  autocmd BufReadPost fugitive://* set bufhidden=delete
augroup END
" Set Gstatus to fixed length
nmap <leader>gg :Git<CR>:10wincmd_<CR>
nmap <leader>gb :Git blame<CR>
nmap <leader>gc :Git commit<CR>
nmap <leader>gd :Gvdiffsplit<CR>
nmap <leader>gf :Git fetch<CR>
nmap <leader>gp :Git pull --rebase<CR>
nmap <leader>gl :Gclog<CR>
nmap <leader>gw :Gwrite<CR>
nmap <leader>gr :Gread<CR>

nnoremap <leader>fn :NERDTreeToggle<CR>
let g:NERDTreeAutoDeleteBuffer=1
let g:NERDTreeShowLineNumbers=1

" Vinegar/netrw enable relative line number
"let g:netrw_bufsettings="noma nomod nonu nobl nowrap ro rnu"
" Disable fast browse, this prevents netrw from opening a buffer
"Let g:netrw_fastbrowse = 0
function! s:opendir(cmd) abort
  if expand('%') =~# '^$\|^term:[\/][\/]'
    execute a:cmd '.'
  else
    execute a:cmd '%:h' . (expand('%:p') =~# '^\a\a\+:' ? s:slash() : '')
  endif
endfunction
nnoremap <silent> <Plug>VinegarUp :call <SID>opendir('edit')<CR>
if empty(maparg('-', 'n')) && !hasmapto('<Plug>VinegarUp')
  nmap - <Plug>VinegarUp
endif

" Grepper
let g:grepper = {}
let g:grepper.tools = ['ag', 'git', 'grep']
let g:grepper.repo = ['.git', '.hg', '.svn']
let g:grepper.dir = 'repo'
let g:grepper.highlight = 1
let g:grepper.prompt_mapping_tool = '<leader>g'
" Copied from grepper.vim
" I amended the grepprg by adding --ignore-dir build
"let g:grepper.ag.grepprg .= ' --ignore-dir build'
let g:grepper.ag = {
    \ 'grepprg':    'ag --vimgrep --ignore-dir build',
    \ 'grepformat': '%f:%l:%c:%m,%f:%l:%m,%f',
    \ 'escape':     '\^$.*+?()[]{}|' }

nnoremap <leader>ss :Grepper -tool ag<cr>
nnoremap <leader>sg :Grepper -tool git -cword -noprompt<cr>
nnoremap <leader>sa :Grepper -tool ag -cword -noprompt<cr>

" Signature
" The periodic refresh kills performance
let g:SignaturePeriodicRefresh = 0

" Use <ctrl>-e (instead of <ctrl>-<shift>-6) for buffer transition
nnoremap <C-e> <C-^>
" Use <ctrl>-s to open split on the right
nnoremap <C-s> :<C-u>execute 'vert belowright sb ' . v:count<CR>

nmap <leader>y <Plug>OSCYankOperator
vmap <leader>y <Plug>OSCYankVisual

" CurtineIncSw
nmap <silent> <Leader>a :call CurtineIncSw()<cr>

" Auto save
let g:auto_save = 1

" Automatically deletes least recently used buffer
" let g:bufmru_nb_to_keep = 25

let g:tmuxline_powerline_separators = 0

" Coc settings
" Extensions
let g:coc_global_extensions = ['coc-tsserver', 'coc-json', 'coc-pyright']
let g:coc_disable_startup_warning = 1

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo because accepting a completion or inserting a
" newline is treated as a separate undo step
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

nnoremap <silent> K :call ShowDocumentation()<CR>
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Symbol renaming
nmap <leader>cr <Plug>(coc-rename)

" Apply the most preferred quickfix action to fix diagnostic on the current
" line
nmap <leader>cf <Plug>(coc-fix-current)

" Vimspector, needs setup using below
" :VimspectorInstall vscode-cpptools
nnoremap <Leader>dd :call vimspector#Launch()<CR>
nnoremap <Leader>de :call vimspector#Reset()<CR>
nnoremap <Leader>dc :call vimspector#Continue()<CR>

nnoremap <Leader>db :call vimspector#ToggleBreakpoint()<CR>
nnoremap <Leader>dB :call vimspector#ClearBreakpoints()<CR>

nmap <Leader>dk <Plug>VimspectorRestart
nmap <Leader>dh <Plug>VimspectorStepOut
nmap <Leader>dl <Plug>VimspectorStepInto
nmap <Leader>dj <Plug>VimspectorStepOver
nmap <leader>J <Plug>VimspectorBalloonEval

" Termdebug Mappings
nmap E :Evaluate<CR>
nmap J :Over<CR>
nmap S :Step<CR>
nmap B :Break<CR>
nmap D :Clear<CR>
nmap C :Continue<CR>

" Call :Dbg to load and run debugging session
function! s:AdjustTermdebugLayout() abort
  " Move terminal window to bottom
  wincmd k
  wincmd J
  " Resize top for it to capture majority of height
  wincmd t
  let l:full_height = str2float(&lines)
  let l:source_height = float2nr(l:full_height * 0.7)
  execute "resize " . l:source_height
  " Move focus back to gdb window
  wincmd j
  let l:gdb_height = float2nr(l:full_height * 0.2)
  execute "resize " . l:gdb_height
endfunction

let g:dbg_loaded = 0
function! s:LoadTermdebug(...) abort
  if g:dbg_loaded == 0
    packadd termdebug
    let g:dbg_loaded = 1
  endif
  execute 'Termdebug' join(a:000, ' ')
  " Customize layout: Move GDB output pane to the bottom
  call s:AdjustTermdebugLayout()
endfunction
command! -nargs=* Dbg call s:LoadTermdebug(<q-args>)

let g:termdebug_config = {}
" Both windows are disabled by default
" Use :Asm to open
let g:termdebug_config['disasm_window'] = v:false
" Use :Var to open
let g:termdebug_config['variables_window'] = v:false
let g:termdebug_config['evaluate_in_popup'] = v:true
" K is already mapped in coc.nvim, it is mapped to E instead
let g:termdebug_config['map_K'] = v:false
