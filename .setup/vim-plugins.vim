set nocompatible
set eventignore=all
execute 'set runtimepath^=' . fnameescape($RC_SETUP_HOME . '/.vim')
execute 'source ' . fnameescape($RC_SETUP_REPO . '/vim/.vim/config/plugins.vim')
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
