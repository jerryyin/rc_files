" Generic tool and integration configuration.
let s:config_dir = has('win32') ? g:personal_windows_vim_config : expand('<sfile>:p:h')

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
let g:Lf_CacheDirectory = empty($XDG_CACHE_HOME) ? expand('~/.cache') : $XDG_CACHE_HOME
silent! call mkdir(g:Lf_CacheDirectory, 'p')
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
let s:python = has('win32') ? 'py -3' : 'python3'
let g:Lf_ExternalCommand = s:python . ' ' . shellescape(expand('<sfile>:p:h') . '/project-files.py') . ' %s'

" Grepper
let g:grepper = {}
let g:grepper.tools = ['rg', 'git', 'grep']
let g:grepper.repo = ['.git', '.hg', '.svn']
let g:grepper.dir = 'repo'
let g:grepper.highlight = 1
let g:grepper.prompt_mapping_tool = '<leader>g'
let g:grepper.rg = {
    \ 'grepprg': 'rg --vimgrep --smart-case --max-columns 500 --max-columns-preview --glob !build/**',
    \ 'grepformat': '%f:%l:%c:%m' }

nnoremap <leader>ss :Grepper -tool rg<CR>
nnoremap <leader>sg :Grepper -tool git -cword -noprompt<cr>
nnoremap <leader>sa :Grepper -tool rg -cword -noprompt<CR>

" Copy to tmux clipboard and paste from tmux clipboard
let s:mux = has('win32') ? 'psmux' : 'tmux'
execute 'vnoremap <leader>ty y<CR>:call system(' . string(s:mux . ' load-buffer -') . ', @0)<CR>gv'
execute 'nnoremap <leader>tp :let @0 = system(' . string(s:mux . ' save-buffer -') . ')<CR>"0p<CR>g;'
execute 'nnoremap <silent> <leader>tc :let @" = GetMLIRTestCommand()<CR>:call system(' . string(s:mux . ' load-buffer -') . ', @")<CR>'

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
nnoremap <leader>gd :Gvdiffsplit HEAD<CR>
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
nnoremap <leader>g? :help fugitive-maps<CR>
nnoremap <leader>gw :Gwrite<CR>

" \gr: list every commit of this branch, each followed by its changed files.
" \gR: list the files changed by the whole branch as one diff.
" The base is the remote default branch HEAD forked from most recently; the
" cursor starts on the commit being viewed (e.g. from \gl), else on the first
" commit.
function! s:Git(args) abort
  let l:r = FugitiveExecute(a:args)
  if l:r.exit_status
    throw 'git ' . join(a:args) . ': ' . join(l:r.stderr)
  endif
  return filter(l:r.stdout, '!empty(v:val)')
endfunction
" Git records no base branch (@{upstream} is where a branch is pushed), so
" every remote's default branch is a candidate: <remote>/HEAD, which only clone
" and remote set-head create, else <remote>/main or master. The base is the
" merge-base that leaves the fewest commits on the branch, which is the
" project's branch rather than a fork's stale main, whatever the remotes are
" called.
function! s:BranchBase() abort
  let l:best = {}
  let l:tried = []
  for l:remote in s:Git(['remote'])
    for l:ref in [l:remote . '/HEAD', l:remote . '/main', l:remote . '/master']
      if FugitiveExecute(['rev-parse', '-q', '--verify', l:ref . '^{commit}']).exit_status == 0
        let l:mb = s:Git(['merge-base', 'HEAD', l:ref])[0]
        let l:n = str2nr(s:Git(['rev-list', '--count', l:mb . '..HEAD'])[0])
        if empty(l:best) || l:n < l:best.n
          let l:best = {'n': l:n, 'base': l:mb}
        endif
        break
      endif
      call add(l:tried, l:ref)
    endfor
  endfor
  if empty(l:best)
    throw 'no base branch: tried ' . join(l:tried, ', ')
  endif
  return l:best.base
endfunction
" One row per changed file. The listed file is the new side (the old side for
" deletions); the row's left side ('' when there is none) is kept in context.
" a:dirty lists the files whose work-tree copy differs from HEAD, or is v:null
" when a:to is not HEAD. A new side that matches the work tree is listed as the
" work-tree file, so Coc's language servers (which only read files on disk)
" work in it.
function! s:FileRows(from, to, items, lefts, dirty) abort
  let l:n = 0
  for l:line in s:Git(['diff', '--name-status', '-M', a:from, a:to])
    let l:f = split(l:line, '\t')
    let l:st = l:f[0][0]
    let l:old = l:f[1]
    let l:new = l:f[-1]
    let l:path = l:st ==# 'D' ? a:from . ':' . l:old : a:to . ':' . l:new
    let l:file = l:st !=# 'D' && type(a:dirty) == v:t_list && index(a:dirty, l:new) < 0
          \ ? FugitiveWorkTree() . '/' . l:new : FugitiveFind(l:path)
    call add(a:items, {'valid': 1, 'filename': l:file, 'module': l:path,
          \ 'text': l:st . '  ' . (l:st =~# '[RC]' ? l:old . ' -> ' . l:new : l:new)})
    call add(a:lefts, l:st =~# '[AD]' ? '' : a:from . ':' . l:old)
    let l:n += 1
  endfor
  return l:n
endfunction
function! s:Header(items, lefts) abort
  call add(a:items, {'valid': 0, 'text': ''})
  call add(a:lefts, '')
  return len(a:items) - 1
endfunction
function! s:BranchReview(together) abort
  try
    let l:base = s:BranchBase()
    let l:head = s:Git(['rev-parse', 'HEAD'])[0]
    let l:shas = s:Git(['rev-list', '--reverse', '--no-merges', l:base . '..' . l:head])
    if empty(l:shas)
      echo 'No commits between ' . l:base[0:7] . ' and HEAD'
      return
    endif
    let l:viewed = matchstr(FugitiveParse(expand('%'))[0], '^\x\{7,}$')
    let l:items = []
    let l:lefts = []
    let l:target = 0
    let l:dirty = s:Git(['diff', '--name-only', 'HEAD'])
    if a:together
      let l:h = s:Header(l:items, l:lefts)
      let l:n = s:FileRows(l:base, l:head, l:items, l:lefts, l:dirty)
      let l:items[l:h].text = '▸ ' . l:base[0:7] . '..' . l:head[0:7] . '  '
            \ . len(l:shas) . ' commits  (' . l:n . ' files)'
    else
      for l:sha in l:shas
        let l:h = s:Header(l:items, l:lefts)
        let l:n = s:FileRows(s:Git(['rev-parse', l:sha . '^'])[0], l:sha, l:items, l:lefts,
              \ l:sha ==# l:head ? l:dirty : v:null)
        let l:items[l:h].text = '▸ ' . l:sha[0:7] . '  '
              \ . s:Git(['log', '-1', '--format=%s', l:sha])[0]
              \ . '  (' . l:n . (l:n == 1 ? ' file)' : ' files)')
        if !empty(l:viewed) && stridx(l:sha, l:viewed) == 0
          let l:target = l:h
        endif
      endfor
    endif
    call setqflist([], ' ', {'items': l:items,
          \ 'title': 'Branch review: ' . (a:together ? 'together' : 'by commit')
          \ . ' since ' . l:base[0:7],
          \ 'context': {'branch_review_lefts': l:lefts},
          \ 'quickfixtextfunc': function('s:BranchReviewText')})
  catch
    echohl ErrorMsg | echomsg v:exception | echohl None
    return
  endtry
  botright copen
  call s:OpenListedDiff(l:target + 1)
endfunction
function! s:BranchReviewText(info) abort
  let l:items = getqflist({'id': a:info.id, 'items': 1}).items
  return map(l:items[a:info.start_idx - 1 : a:info.end_idx - 1],
        \ {_, it -> it.valid ? '    ' . it.text : it.text})
endfunction
nnoremap <silent> <leader>gr :call <SID>BranchReview(0)<CR>
nnoremap <silent> <leader>gR :call <SID>BranchReview(1)<CR>
" Compare the current quickfix entry with its left side: the one recorded by
" \gr / \gR, else the commit's parent (as `:Git difftool` lists expect).
function! s:DiffCurrentEntry() abort
  let l:q = getqflist({'idx': 0, 'context': 0})
  let l:ctx = l:q.context
  if type(l:ctx) == v:t_dict && has_key(l:ctx, 'branch_review_lefts')
    let l:left = l:ctx.branch_review_lefts[l:q.idx - 1]
    if !empty(l:left)
      execute 'keepalt Gvdiffsplit! ' . fnameescape(l:left)
    endif
  else
    keepalt Gvdiffsplit!
  endif
endfunction
" ]d / [d: close this comparison, go to the next/previous file, compare it.
" Close first: once the file changes, Fugitive turns diff off in the old
" pane and DiffClose no longer closes it. :cnext skips commit header rows.
nnoremap <silent> ]d :call fugitive#DiffClose()<Bar>cnext<Bar>call <SID>DiffCurrentEntry()<CR>
nnoremap <silent> [d :call fugitive#DiffClose()<Bar>cprevious<Bar>call <SID>DiffCurrentEntry()<CR>
" Enter in a `:Git difftool` or branch review quickfix list opens that file's
" comparison (a commit header opens its first file); other lists keep the
" default Enter.
function! s:IsDifftoolList() abort
  if getwininfo(win_getid())[0].loclist
    return 0
  endif
  let l:q = getqflist({'title': 0, 'context': 0})
  return l:q.title =~# '^:Git\>.*\<difftool\>'
        \ || (type(l:q.context) == v:t_dict && has_key(l:q.context, 'branch_review_lefts'))
endfunction
function! s:OpenListedDiff(idx) abort
  let l:items = getqflist()
  let l:idx = a:idx
  while l:idx <= len(l:items) && !l:items[l:idx - 1].valid
    let l:idx += 1
  endwhile
  if l:idx > len(l:items)
    return
  endif
  wincmd p
  call fugitive#DiffClose()
  execute 'cc ' . l:idx
  call s:DiffCurrentEntry()
endfunction
augroup difftoolEnter
  autocmd!
  autocmd FileType qf nnoremap <buffer><silent><expr> <CR> <SID>IsDifftoolList()
        \ ? ":\<C-U>call <SID>OpenListedDiff(line('.'))\<CR>" : "\<CR>"
augroup END

nmap <leader>yy <Plug>OSCYankOperator
vmap <leader>y <Plug>OSCYankVisual

" Coc settings
" Extensions
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

" GoTo code navigation. Language servers only read files on disk, so in a
" fugitive:// buffer (a file as of some commit, e.g. a review diff pane) the
" lookup runs from the work-tree copy, opened in a new tab on the same line
" (the nearest identical line, else the nearest use of the word).
function! s:CocJump(action) abort
  let l:name = bufname('%')
  if l:name =~# '^fugitive:'
    let l:real = FugitiveReal(l:name)
    if !filereadable(l:real)
      echohl WarningMsg | echo 'Not in the work tree: ' . l:real | echohl None
      return
    endif
    let [l:text, l:lnum, l:col, l:word] = [getline('.'), line('.'), col('.'), expand('<cword>')]
    execute 'tabedit ' . fnameescape(l:real)
    let l:pats = ['\V\^' . escape(l:text, '\') . '\$']
    if !empty(l:word)
      call add(l:pats, '\V\<' . escape(l:word, '\') . '\>')
    endif
    let l:found = 0
    for l:pat in l:pats
      call cursor(l:lnum, 1)
      let l:hits = filter([search(l:pat, 'cnW'), search(l:pat, 'bnW')], 'v:val > 0')
      if !empty(l:hits)
        let l:best = sort(l:hits, {a, b -> abs(a - l:lnum) - abs(b - l:lnum)})[0]
        call cursor(l:best, 1)
        if l:pat ==# l:pats[0]
          call cursor(l:best, l:col)
        else
          call search(l:pat, 'cW', l:best)
        endif
        let l:found = 1
        break
      endif
    endfor
    if !l:found
      echohl WarningMsg | echo 'No "' . l:word . '" in the work-tree file' | echohl None
      return
    endif
    call CocAction('ensureDocument')
  endif
  call CocActionAsync(a:action)
endfunction
nnoremap <silent> gd :call <SID>CocJump('jumpDefinition')<CR>
nnoremap <silent> gy :call <SID>CocJump('jumpTypeDefinition')<CR>
nnoremap <silent> gi :call <SID>CocJump('jumpImplementation')<CR>
nnoremap <silent> gr :call <SID>CocJump('jumpReferences')<CR>

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
execute 'source ' . fnameescape(expand('<sfile>:p:h') . '/debug.vim')

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
" Claude Code / Codex Integration (tmux-based)
" ============================================================================
" Prerequisite: Claude Code or Codex running in a tmux split.
" Usage:
"   - Visual mode: Select code, hit \cc -> sends selection with context
"   - Normal mode: Hit \cc              -> sends path:line of the cursor
" Either way, focus then moves to the agent pane, after the pasted text.
" The target pane is detected by what it runs (claude/codex in its process
" tree), not by tmux focus history, so it works with >2 panes.
" ============================================================================

xnoremap <leader>cc :call SendToClaudeVisual()<CR>
nnoremap <leader>cc :call SendToClaudeBuffer()<CR>

" Return 1 if any process in the tree rooted at a:pid runs claude or codex.
function! s:PaneRunsAi(pid) abort
    if has('win32')
        return index(get(s:, 'native_ai_pids', []), a:pid) >= 0
    endif
    let frontier = [a:pid]
    while !empty(frontier)
        let next = []
        for p in frontier
            if empty(p) | continue | endif
            let cmdline = system('cat /proc/' . p . '/cmdline 2>/dev/null | tr "\0" " "')
            if cmdline =~? '\vclaude|codex'
                return 1
            endif
            call extend(next, systemlist('pgrep -P ' . p))
        endfor
        let frontier = next
    endwhile
    return 0
endfunction

" Find the tmux pane running Claude Code or Codex. Returns a pane id or ''.
function! s:FindAiPane() abort
    let cur = $TMUX_PANE
    if has('win32')
        let s:native_ai_pids = map(systemlist('powershell.exe -NoProfile -File ' . shellescape(s:config_dir . '/ai-processes.ps1')), 'trim(v:val)')
    endif
    let last = trim(system(s:mux . ' display-message -p -t ' . shellescape('{last}') . ' ' . shellescape('#{pane_id}')))
    let curwin = trim(system(s:mux . ' display-message -p ' . shellescape('#{window_id}')))
    let matches = []
    let curwin_matches = []
    let scope = has('win32') ? '-s' : '-a'
    for row in systemlist(s:mux . ' list-panes ' . scope . ' -F ' . shellescape('#{pane_id} #{pane_pid} #{window_id}'))
        let parts = split(row)
        if len(parts) < 3 | continue | endif
        let [pane, pid, win] = parts[0:2]
        if pane ==# cur | continue | endif
        if s:PaneRunsAi(pid)
            call add(matches, pane)
            if win ==# curwin | call add(curwin_matches, pane) | endif
        endif
    endfor
    if empty(matches) | return '' | endif
    " Prefer the last-focused pane when it is itself an AI pane, then a match in
    " the current window, then any match.
    if index(matches, last) >= 0 | return last | endif
    if !empty(curwin_matches) | return curwin_matches[0] | endif
    return matches[0]
endfunction

" Helper: paste text into the Claude/Codex tmux pane (no Enter, no screen flash)
function! s:PasteToClaudeTmux(text)
    let target = s:FindAiPane()
    if empty(target)
        echohl WarningMsg | echo "No Claude/Codex tmux pane found" | echohl None
        return ''
    endif
    let temp = tempname()
    " Binary mode omits the final newline, which tmux would paste as Enter.
    call writefile(split(a:text, "\n", 1), temp, 'b')
    call system(s:mux . ' load-buffer ' . shellescape(temp))
    call system(s:mux . ' paste-buffer -t ' . shellescape(target))
    call delete(temp)
    " Focus the agent pane, whose input cursor now sits after the pasted text.
    " The pane may be in another window or, on Linux, another session.
    let session = trim(system(s:mux . ' display-message -p -t ' . shellescape(target) . ' ' . shellescape('#{session_id}')))
    if session !=# trim(system(s:mux . ' display-message -p ' . shellescape('#{session_id}')))
        call system(s:mux . ' switch-client -t ' . shellescape(target))
    endif
    call system(s:mux . ' select-window -t ' . shellescape(target))
    call system(s:mux . ' select-pane -t ' . shellescape(target))
    return target
endfunction

function! SendToClaudeVisual() range
    if empty($TMUX) && !(has('win32') && !empty($PSMUX_SESSION))
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

    let target = s:PasteToClaudeTmux(text)
    if !empty(target)
        echo "Pasted to " . target . ": " . filename . " (lines " . line_start . "-" . line_end . ")"
    endif
endfunction

function! SendToClaudeBuffer()
    if empty($TMUX) && !(has('win32') && !empty($PSMUX_SESSION))
        echo "Error: Not in tmux"
        return
    endif

    " Just send file reference - Claude can read the file itself
    let filepath = expand('%:p')
    let cursor_line = line('.')
    let text = filepath . ":" . cursor_line

    let target = s:PasteToClaudeTmux(text)
    if !empty(target)
        echo "Pasted to " . target . ": " . text
    endif
endfunction
