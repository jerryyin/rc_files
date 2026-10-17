" Native Windows settings. Loaded only by the shared vimrc on Windows.
execute 'set runtimepath^=' . fnameescape(expand('~/.vim'))
let g:coc_data_home = expand('~/.config/coc')
let g:startify_session_dir = expand('~/.vim/session')
let g:Lf_PythonVersion = 3

" Bootstrap supplies machine-specific executable locations in the _vimrc loader.
if !empty(get(g:, 'personal_git_bash', ''))
  let &shell = '"' . g:personal_git_bash . '"'
  set shellcmdflag=-c
  set shellquote=
  set shellxquote=\"
  set shellslash
endif
if !empty(get(g:, 'personal_python_dll', ''))
  let $PATH = g:personal_python_root . ';' . $PATH
  let &pythonthreedll = g:personal_python_dll
  let &pythonthreehome = g:personal_python_root
endif
if has('gui_running')
  let &guifont = 'MonacoLigaturized Nerd Font:h10'
endif
