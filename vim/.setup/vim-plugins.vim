set nocompatible
set eventignore=all
" Keep unattended installs sequential; concurrent vim-plug jobs can fail while
" looking up completed jobs in headless Vim.
let g:plug_threads = 1
execute 'set runtimepath^=' . fnameescape(expand('~/.vim'))
let s:package = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
try
  execute 'source ' . fnameescape(s:package . '/.vim/config/plugins.vim')
  if $RC_SETUP_UPDATE ==# '1'
    PlugUpdate --sync
  elseif !empty(filter(copy(values(g:plugs)), '!isdirectory(v:val.dir)'))
    PlugInstall --sync
  else
    echom 'SKIP Vim plugins (installed)'
  endif
  if !empty(filter(values(g:plugs), '!filereadable(v:val.dir . ''/.git/HEAD'')'))
    cquit 1
  endif
  cquit 0
catch
  echom v:throwpoint
  echom v:exception
  cquit 1
endtry
