" UI behavior, navigation, and filetype-local editing settings.

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
  autocmd FileType cpp call s:MaybeActivateAnyFold()
augroup END

" disable anyfold for large files
let g:LargeFile = 1000000 " file is large if size greater than 1MB
augroup checkFileSize
  autocmd!
  autocmd BufReadPre * call s:CheckLargeFile(expand('<afile>'))
  autocmd BufReadPost * call s:ApplyLargeFileSettings()
augroup END

function! s:MaybeActivateAnyFold() abort
  if !get(b:, 'large_file', 0)
    AnyFoldActivate
  endif
endfunction

function! s:CheckLargeFile(file) abort
  let l:size = getfsize(a:file)
  if l:size > g:LargeFile || l:size == -2
    let b:large_file = 1
  endif
endfunction

function! s:ApplyLargeFileSettings() abort
  if get(b:, 'large_file', 0)
    setlocal foldmethod=indent
  endif
endfunction

" Coding styles
" shiftwidth: >> indent; tabstop: how long a tab is
augroup ft
  autocmd!
  " Can enable filetype specific settings
  autocmd FileType qf setlocal wrap
  autocmd FileType * call s:EnableSpellForNormalBuffer()
  autocmd FileType mlir setlocal iskeyword+=%
  autocmd BufNewFile,BufRead *.cu set filetype=cuda
  autocmd BufNewFile,BufRead *.inc set syntax=cpp
  autocmd BufNewFile,BufRead *.dockerfile set filetype=dockerfile
  autocmd FileType pov setlocal syntax=cpp
  " Triton IR file extensions -> mlir syntax
  autocmd BufNewFile,BufRead *.ttir set filetype=mlir
  autocmd BufNewFile,BufRead *.ttgir set filetype=mlir
  autocmd BufNewFile,BufRead *.llir set filetype=llvm
  autocmd BufNewFile,BufRead *.amdgcn set filetype=asm
augroup END

function! s:EnableSpellForNormalBuffer() abort
  if &buftype ==# ''
    setlocal spell
  endif
endfunction

" Auto-pair
let g:AutoPairsFlyMode = 0

" winresizer
let g:winresizer_start_key = '<C-t>'
let g:winresizer_finish_with_escape = 1

let g:vista#renderer#enable_icon = 1
let g:vista#executives = ['coc', 'ctags']
let g:vista_default_executive = 'ctags'
let g:vista_executive_for = {'cc': 'coc', 'c': 'coc', 'cpp': 'coc'}
nnoremap <leader>vv :Vista!!<CR>
function! NearestMethodOrFunction() abort
  return get(b:, 'vista_nearest_method_or_function', '')
endfunction

let g:startify_lists = [
    \ { 'type': 'sessions',  'header': ['   Sessions']       },
    \ { 'type': 'dir',       'header': ['   MRU '. getcwd()] },
    \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      },
    \ { 'type': 'commands',  'header': ['   Commands']       },
    \ ]

" Disable cursor blinking
set guicursor=n-v-c:block-blinkon0,o:hor50-blinkon0,i-ci:hor15-blinkon0,r-cr:hor30-blinkon0,sm:block-blinkon0
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

" Do not allow auto-resize of quickfix window
augroup QuickfixCustomSettings
  autocmd!
  " Apply AnsiEsc when buffer is loaded, one time setup
  autocmd FileType qf silent! AnsiEsc
augroup END
" Escape sequence for Ansi
nnoremap <leader>ea :AnsiEsc<CR>

" Indent guides
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_start_level = 3
" Default value is 30, kills performance
let g:indent_guides_indent_levels = 8

" auto-format plugin (remap =)
" https://github.com/Chiel92/vim-autoformat/issues/192#issuecomment-316621090
" Do not enable auto format on save
xnoremap = :Autoformat<CR>
nnoremap =G :.,$Autoformat<CR>
nnoremap == :.Autoformat<CR>
nnoremap =% v%:Autoformat<CR>
" Disable fallback to vim's indent file, only remove trailing whitespace
let g:autoformat_autoindent = 0
let g:autoformat_retab = 0

nnoremap <leader>fn :NERDTreeToggle<CR>
let g:NERDTreeAutoDeleteBuffer=1
let g:NERDTreeShowLineNumbers=1
let g:NERDTreeShowHidden=1
let g:NERDTreeMapUpdir='-'

function! s:opendir(cmd) abort
  if expand('%') =~# '^$\|^term:[\/][\/]'
    execute a:cmd fnameescape('.')
  else
    execute a:cmd fnameescape(expand('%:p:h'))
  endif
endfunction
nnoremap - :call <SID>opendir('edit')<CR>

" Signature
" The periodic refresh kills performance
let g:SignaturePeriodicRefresh = 0

" Use <ctrl>-e (instead of <ctrl>-<shift>-6) for buffer transition
nnoremap <C-e> <C-^>
" Use <ctrl>-s to open split on the right
nnoremap <C-s> :<C-u>execute 'vert belowright sb ' . v:count<CR>

" CurtineIncSw
nnoremap <silent> <Leader>a :call CurtineIncSw()<cr>

" Auto save
let g:auto_save = 1

" Automatically deletes least recently used buffer
" let g:bufmru_nb_to_keep = 25
