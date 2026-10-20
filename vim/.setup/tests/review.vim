set nomore
let g:auto_save = 0
execute 'set runtimepath^=' . fnameescape($RC_REVIEW_FUGITIVE)
runtime plugin/fugitive.vim
let s:results = []
let s:error = ''
try
  for s:case in [
        \ ['unstaged', '', 'Gvdiffsplit'],
        \ ['combined', '', 'Gvdiffsplit HEAD'],
        \ ['staged', 'Gedit :0:review.py', 'Gvdiffsplit HEAD'],
        \ ['past commit', 'Gedit HEAD:review.py', 'Gvdiffsplit HEAD^']]
    execute 'tabedit ' . fnameescape($RC_REVIEW_PROJECT . '/review.py')
    if !empty(s:case[1]) | execute s:case[1] | endif
    execute s:case[2]
    let s:windows = []
    for s:window in getwininfo()
      if s:window.tabnr == tabpagenr() && getwinvar(s:window.winid, '&diff')
        call add(s:windows, {'wrap': getwinvar(s:window.winid, '&wrap'),
              \ 'fugitive': bufname(s:window.bufnr) =~# '^fugitive:'})
      endif
    endfor
    diffoff!
    call add(s:results, {'case': s:case[0], 'windows': s:windows, 'after': &l:wrap})
    tabclose
  endfor
catch
  let s:error = v:exception . ' at ' . v:throwpoint
endtry
call writefile([json_encode({'cases': s:results, 'error': s:error})], $RC_REVIEW_REPORT)
