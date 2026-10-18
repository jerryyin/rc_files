" Native Windows settings. Loaded only by the shared vimrc on Windows.
let g:personal_windows_vim_config = expand('<sfile>:p:h')
execute 'set runtimepath^=' . fnameescape(expand('~/.vim'))
let g:coc_data_home = expand('~/.config/coc')
let g:startify_session_dir = expand('~/.vim/session')
let g:Lf_PythonVersion = 3

" Windows plugins launch cmd.exe directly and need the same quoting as Vim.
let &shell = empty($COMSPEC) ? 'cmd.exe' : $COMSPEC
set shellcmdflag=/c shellquote= shellxquote=\" noshellslash
let &shellpipe = '>%s 2>&1'
if has('gui_running')
  let &guifont = 'MonacoLigaturized Nerd Font:h10'
endif
