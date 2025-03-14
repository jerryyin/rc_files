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
Plug 'ludovicchabant/vim-gutentags'

" Code formating
Plug 'vim-autoformat/vim-autoformat'
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
  autocmd FileType qf setlocal wrap
  autocmd FileType mlir setlocal iskeyword+=%
  autocmd BufNewFile,BufRead *.cu set filetype=cuda
  autocmd BufNewFile,BufRead *.inc set syntax=cpp
  autocmd BufNewFile,BufRead *.dockerfile set filetype=dockerfile
  autocmd FileType pov setlocal syntax=cpp
augroup END

" Auto-pair
let g:AutoPairsFlyMode = 0

" Lens
let g:lens#width_resize_max = 85

" winresizer
let g:winresizer_start_key = '<C-t>'
let g:winresizer_finish_with_escape = 1

let g:vista#renderer#enable_icon = 1
let g:vista#executives = ['coc', 'ctags']
let g:vista_default_executive = 'ctags'
let g:vista_executive_for = {'cc': 'coc', 'c': 'coc', 'cpp': 'coc'}
nmap <leader>vv :Vista!!<CR>
function! NearestMethodOrFunction() abort
  return get(b:, 'vista_nearest_method_or_function', '')
endfunction

" lightline
" Customize colorscheme, branch and tabline
set showtabline=2
set laststatus=2
set noshowmode
let g:lightline = {
  \ 'colorscheme': 'gruvbox_material',
  \ 'active': {
  \   'left': [['mode', 'paste'],
  \            ['gitbranch', 'readonly', 'modified', 'filename', 'method']],
  \   'right': [['lineinfo'], ['percent'], ['filetype']]
  \ },
  \ 'component_function': {
  \   'gitbranch': 'FugitiveHead',
  \   'method': 'NearestMethodOrFunction'
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

let g:startify_lists = [
    \ { 'type': 'sessions',  'header': ['   Sessions']       },
    \ { 'type': 'dir',       'header': ['   MRU '. getcwd()] },
    \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      },
    \ { 'type': 'commands',  'header': ['   Commands']       },
    \ ]

let g:startify_session_persistence = 1
" Function to get the default session name based on the current file's directory
function! GetDefaultSession()
  return fnamemodify(getcwd(), ':t') . ".vim"
endfunction

" Session is only tracked when:
" 1. SSave is invoked
" 2. Session is loaded from Startify
augroup StartifyGroup
  autocmd!
  autocmd VimEnter * nested
    \ if !argc() && empty(v:this_session) && !&modified |
      \ let default_session = expand("~/.vim/session/") . GetDefaultSession() |
      \ if !filereadable(default_session) |
      \   execute "SSave! " . GetDefaultSession() |
      \ endif |
    \ endif
augroup END

" Mappings for session commands
nnoremap <leader>sl :execute 'SLoad ' . GetDefaultSession()<CR>
nnoremap <leader>sv :execute 'SSave! ' . GetDefaultSession()<CR>
nnoremap <leader>sd :execute 'SDelete! ' . GetDefaultSession()<CR>

" Dispatch, disallow tmux pane capture trick
set shellpipe=2>&1\|tee
let g:dispatch_no_maps = 1
nnoremap <leader>qo :Copen<CR>:10wincmd_<CR>
nnoremap <leader>qc :cclose<CR>

nnoremap <leader>bb :CMakeBuild<CR>
nnoremap <leader>bc :CMakeBuild --target clean<CR>
" IREE specific setup, do ROCm build
nnoremap <leader>bp :CMakePreset dbg -Wno-dev<CR>
nnoremap <leader>tt :CMakeTest -R %:t --output-on-failure -E 'cuda\|metal\|vulkan\|cpu\|e2e'<CR>
nnoremap <leader>ta :CMakeTest all -j32 --output-on-failure -E 'cuda\|metal\|vulkan\|cpu\|e2e'<CR>

" Copy to tmux clipboard and paste from tmux clipboard
vnoremap <leader>ty y<cr>:call system("tmux load-buffer -", @0)<cr>gv
nnoremap <leader>tp :let @0 = system("tmux save-buffer -")<cr>"0p<cr>g;"

" Do not allow auto-resize of quickfix window
let g:lens#disabled_filetypes = ['qf', 'fugitive', 'termdebug', 'vista', '']
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
" Exclude build, include third_party/llvm-project/mlir, and everything else
let g:Lf_ExternalCommand = 'cd %s && git ls-files --recurse-submodules | grep -v "^build/" | grep -E "^(third_party/llvm-project/mlir/|[^t])"'

" Fugitive
augroup fuDeleteBuffer
  autocmd!
  autocmd BufReadPost fugitive://* set bufhidden=delete
augroup END

function! s:toggle_gstatus() abort
  for l:winnr in range(1, winnr('$'))
    if !empty(getwinvar(l:winnr, 'fugitive_status'))
      execute l:winnr . 'close'
      return
    endif
  endfor
  Git
  execute "10wincmd _"
endfunction
nnoremap <leader>gg :call <SID>toggle_gstatus()<CR>
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
let g:NERDTreeShowHidden=1
let g:NERDTreeMapUpdir='-'

function! s:opendir(cmd) abort
  if expand('%') =~# '^$\|^term:[\/][\/]'
    execute a:cmd '.'
  else
    execute a:cmd '%:h' . (expand('%:p') =~# '^\a\a\+:' ? s:slash() : '')
  endif
endfunction
nmap - :call <SID>opendir('edit')<CR>

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

nmap <leader>yy <Plug>OSCYankOperator
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
let g:coc_global_extensions = ['coc-tsserver', 'coc-json', 'coc-pyright', 'coc-snippets']
let g:coc_disable_startup_warning = 1

" Use <c-t> to trigger completion
inoremap <silent><expr> <c-t> coc#refresh()

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

" Termdebug Mappings
nmap E :Evaluate<CR>
nmap J :Over<CR>
nmap S :Step<CR>
nmap B :Break<CR>
nmap D :Clear<CR>
nmap C :Continue<CR>

function! s:AdjustLayout() abort
  " Get window layout
  let l:layout = winlayout()
  let l:full_height = str2float(&lines)

  if l:layout[0] != 'col'
    return
  endif

  let l:num_panes = len(l:layout[1])
  let l:source_ratio = (l:num_panes == 2) ? 0.8 : 0.7
  let l:gdb_ratio = 0.2
  let l:full_height = str2float(&lines)

  wincmd t
  execute "resize " . float2nr(l:full_height * l:source_ratio)
  wincmd j
  execute "resize " . float2nr(l:full_height * l:gdb_ratio)
endfunction

let g:dbg_loaded = 0
function! s:RunTermdebug(...) abort
  if g:dbg_loaded == 0
    packadd termdebug
    let g:dbg_loaded = 1
  endif
  " Move source window to be leftmost so wincmd k later works
  wincmd H
  execute 'TermdebugCommand ' join(a:000, ' ')
  " Make GDB window to be global bottom temporarily
  wincmd J
  wincmd k
  " Make Output window to be global bottom
  wincmd J
  " Customize layout: Move GDB output pane to the bottom
  call s:AdjustLayout()
endfunction
command! -nargs=* Dbg call s:RunTermdebug(<q-args>)
nnoremap <Leader>dl :call <SID>AdjustLayout()<CR>

" Copy test command of current buffer into unamed register
"nnoremap <silent> <leader>ty :let @" = GetMLIRTestCommand()<CR>
" Copy test command of current buffer into tmux buffer
nnoremap <silent> <leader>tc :let @" = GetMLIRTestCommand()<CR>:call system("tmux load-buffer -", @0)<CR>
nnoremap <silent> <leader>td :execute 'Dbg '. GetMLIRTestCommand()<CR>
nnoremap <leader>ml :set syntax=mlir<CR>

command! -nargs=1 R :call RunToScratch(<f-args>)
nnoremap <silent> <leader>tr :call RunToScratch(GetMLIRTestCommand())<CR>:set filetype=mlir<CR>

" Convenience function to pipe result from quickfix to Scratch buffer
function! QuickfixToScratch()
  " Open a new vertical split for the scratch buffer
  vertical new
  setlocal buftype=nofile bufhidden=wipe noswapfile filetype=mlir

  " Get the contents of the quickfix list
  let l:quickfix_contents = map(getqflist(), 'v:val.text')

  " Remove the '||' prefix from each line
  let l:filtered_contents = map(l:quickfix_contents, 'substitute(v:val, "^\\s*||\\s*", "", "")')

  " Add the filtered lines to the buffer
  call append(0, l:filtered_contents)
endfunction
" Map <leader>qs to the function
nnoremap <leader>qs :call QuickfixToScratch()<CR>

" \tf only works for the last // RUN command and ignores previous ones
nnoremap <silent> <leader>tf :call GenerateTestChecks('file')<CR>:set filetype=mlir<CR>
" If there are multiple // RUN commands, \tr first and \tb on the scratch buffer
" This wouldn't be necessary if the generate-test-checks.py support (cmd1; cmd2) chained source as input
nnoremap <silent> <leader>tb :call GenerateTestChecks('buffer')<CR>:set filetype=mlir<CR>

let g:termdebug_config = {}
" Both windows are disabled by default
" Use :Asm to open
let g:termdebug_config['disasm_window'] = v:false
" Use :Var to open
let g:termdebug_config['variables_window'] = v:false
let g:termdebug_config['evaluate_in_popup'] = v:true
" K is already mapped in coc.nvim, it is mapped to E instead
let g:termdebug_config['map_K'] = v:false

function! Rnvar()
  " Get the word under the cursor to be replaced
  let word_to_replace = expand("<cword>")
  " Prompt the user for the replacement name
  let replacement = input("New name: ")

  let start = search('^\s*\(func\.func\|util.func\)', 'bW')
  let end = search('^}', 'W')
  echom string(start) . " " . string(end)

  if start == 0 || end == 0
    echo "Not inside a function or function boundaries not found."
    return
  endif

  " Perform substitution within the function boundaries
  execute start . ',' . end . 's/\V\<'.word_to_replace.'\>/'.replacement.'/gc'
endfunction
nnoremap <leader>rn :call Rnvar()<CR>
