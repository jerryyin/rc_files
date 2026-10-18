" Native Windows settings. Loaded only by the shared vimrc on Windows.
execute 'set runtimepath^=' . fnameescape(expand('~/.vim'))
let g:coc_data_home = expand('~/.config/coc')
let g:startify_session_dir = expand('~/.vim/session')
let g:Lf_PythonVersion = 3

" Windows plugins launch cmd.exe directly and need the same quoting as Vim.
let &shell = empty($COMSPEC) ? 'cmd.exe' : $COMSPEC
set shellcmdflag=/c shellquote= shellxquote=\" noshellslash
let &shellpipe = '>%s 2>&1'
" The tracked _vimrc reads discovered executable locations from machine-paths.json.
if !empty(get(g:, 'personal_python_dll', ''))
  let $PATH = g:personal_python_root . ';' . $PATH
  let &pythonthreedll = g:personal_python_dll
  let &pythonthreehome = g:personal_python_root
endif
if has('gui_running')
  let &guifont = 'MonacoLigaturized Nerd Font:h10'
endif
