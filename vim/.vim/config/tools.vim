" Generic tool and integration configuration.

" gutentags settings
let g:gutentags_generate_on_new = 1
let g:gutentags_generate_on_missing = 1
let g:gutentags_generate_on_write = 1
let g:gutentags_generate_on_empty_buffer = 0
let g:gutentags_project_root = ['.root', '.svn', '.git', '.hg', '.project']
let g:gutentags_ctags_tagfile = '.tags'
let g:gutentags_cache_dir = expand('~/.cache/vim-gutentags')
silent! call mkdir(g:gutentags_cache_dir, 'p')
let g:gutentags_modules = []
if executable('ctags')
    let g:gutentags_modules += ['ctags']
endif

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
let g:Lf_PreviewResult = {'Function':0, 'BufTag':0, 'Buffer':0, 'File':0}
let g:Lf_WindowPosition = 'popup'
let g:Lf_PopupWidth = 0.3
" Project-aware file listing:
" - IREE: Include third_party/llvm-project/mlir, exclude other third_party
" - Triton: Include third_party/amd, proton; exclude f2reduce, nvidia
" - Other: Include all files
let g:Lf_ExternalCommand = 'cd %s && (git ls-files --recurse-submodules 2>/dev/null; find build -name "*.inc" 2>/dev/null) | if [ -d "iree" ]; then grep -E "^(third_party/llvm-project/mlir/|[^t])"; elif [ -d "python/triton" ]; then grep -v -E "^third_party/(f2reduce|nvidia)/"; else cat; fi'

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

" Copy to tmux clipboard and paste from tmux clipboard
vnoremap <leader>ty y<cr>:call system("tmux load-buffer -", @0)<cr>gv
nnoremap <leader>tp :let @0 = system("tmux save-buffer -")<cr>"0p<cr>g;"

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
nnoremap <leader>gb :Git blame<CR>
nnoremap <leader>gc :Git commit<CR>
nnoremap <leader>gd :Gvdiffsplit<CR>
function! s:GitClangFormatHere() abort
  let l:bufdir = expand('%:p:h')
  let l:root = systemlist('git -C ' . shellescape(l:bufdir) . ' rev-parse --show-toplevel')
  if v:shell_error || empty(l:root)
    echo "Not a git repo"
    return
  endif
  let l:cwd = getcwd()
  execute 'cd ' . fnameescape(l:root[0])
  Git clang-format
  execute 'cd ' . fnameescape(l:cwd)
endfunction
nnoremap <leader>gf :call <SID>GitClangFormatHere()<CR>
nnoremap <leader>gp :Git pull --rebase<CR>
nnoremap <leader>gl :Gclog<CR>
nnoremap <leader>gw :Gwrite<CR>
nnoremap <leader>gr :Gread<CR>

nmap <leader>yy <Plug>OSCYankOperator
vmap <leader>y <Plug>OSCYankVisual

" Coc settings
" Extensions
let g:coc_global_extensions = ['coc-tsserver', 'coc-json', 'coc-pyright', 'coc-snippets']
let g:coc_disable_startup_warning = 1
" Work around Node 25 localStorage requirement: provide a storage file for coc's node runtime
silent! call mkdir(expand('~/.cache'), 'p')
silent! call writefile([], expand('~/.cache/coc-node-localstorage'), 'a')
let g:coc_node_args = ['--localstorage-file', expand('~/.cache/coc-node-localstorage')]

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

let g:termdebug_config = {}
" Both windows are disabled by default
" Use :Asm to open
let g:termdebug_config['disasm_window'] = v:false
" Use :Var to open
let g:termdebug_config['variables_window'] = v:false
let g:termdebug_config['evaluate_in_popup'] = v:true
" K is already mapped in coc.nvim, it is mapped to E instead
let g:termdebug_config['map_K'] = v:false

" ============================================================================
" Claude Code Integration (tmux-based)
" ============================================================================
" Prerequisite: Claude running in tmux split (manual: tmux split-window -h claude)
" Usage:
"   - Visual mode: Select code, hit \c  -> sends selection with context
"   - Normal mode: Hit \c               -> sends entire buffer with line numbers
" ============================================================================

xnoremap <leader>cc :call SendToClaudeVisual()<CR>
nnoremap <leader>cc :call SendToClaudeBuffer()<CR>

" Helper: paste text into Claude tmux pane (no Enter, no screen flash)
function! s:PasteToClaudeTmux(text)
    let temp = tempname()
    call writefile(split(a:text, "\n", 1), temp)
    call system('tmux load-buffer ' . shellescape(temp))
    call system('tmux paste-buffer -t {last}')
    call delete(temp)
endfunction

function! SendToClaudeVisual() range
    if empty($TMUX)
        echo "Error: Not in tmux"
        return
    endif

    " a:firstline and a:lastline are set by vim from the visual selection
    let line_start = a:firstline
    let line_end = a:lastline
    let lines = getline(line_start, line_end)
    let filename = expand('%:t')

    " Build context header + code
    let text = printf("File: %s (lines %d-%d)\n\n", filename, line_start, line_end)
    let text .= join(lines, "\n")

    call s:PasteToClaudeTmux(text)
    echo "Pasted to Claude: " . filename . " (lines " . line_start . "-" . line_end . ")"
endfunction

function! SendToClaudeBuffer()
    if empty($TMUX)
        echo "Error: Not in tmux"
        return
    endif

    " Just send file reference - Claude can read the file itself
    let filepath = expand('%:p')
    let cursor_line = line('.')
    let text = filepath . ":" . cursor_line

    call s:PasteToClaudeTmux(text)
    echo "Pasted to Claude: " . text
endfunction
