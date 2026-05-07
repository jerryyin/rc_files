" IREE/Triton project-aware build, test, and MLIR helper commands.

" Project detection helper - check if repo name contains 'triton' anywhere
function! IsTritonProject()
  " Match any path containing 'triton' (e.g., /triton, /triton-mi450, /my-triton-fork)
  return getcwd() =~? 'triton'
endfunction

function! IsIreeProject()
  return getcwd() =~ '/iree'
endfunction

" Project-aware build command
function! ProjectBuild()
  if IsTritonProject()
    " Triton: incremental C++ build via ninja
    execute 'Dispatch make all'
  elseif IsIreeProject()
    execute 'CMakeBuild'
  else
    echo "Unknown project type"
  endif
endfunction

" Project-aware clean command
function! ProjectClean()
  if IsTritonProject()
    execute 'Dispatch ninja -C build/cmake.* clean'
  elseif IsIreeProject()
    execute 'CMakeBuild --target clean'
  else
    echo "Unknown project type"
  endif
endfunction

" Pytest compiler settings for quickfix parsing
function! SetPytestCompiler()
  " Error format for pytest --tb=short output:
  "   file.py:123: in test_function
  "   file.py:456: AssertionError
  compiler! pytest
  " Fallback if no pytest compiler exists
  if &makeprg !~ 'pytest'
    setlocal makeprg=pytest\ --tb=short\ -q
    setlocal errorformat=
      \%f:%l:\ in\ %m,
      \%f:%l:\ %m,
      \%E%f:%l:\ %m,
      \%-G%.%#
  endif
endfunction

" Project-aware test current file
function! ProjectTestFile()
  if IsTritonProject()
    " Triton: run pytest on current file
    call SetPytestCompiler()
    let l:file = expand('%:p')
    execute 'Dispatch pytest --tb=short -xvs ' . shellescape(l:file)
  elseif IsIreeProject()
    execute "CMakeTest -R " . fnameescape(expand('%:t')) . " --output-on-failure -E 'cuda\|metal\|vulkan\|cpu\|e2e\|cts'"
  else
    echo "Unknown project type"
  endif
endfunction

" Find the test function name at cursor position
function! GetTestFunctionAtCursor()
  " Save cursor position
  let l:save_pos = getpos('.')
  " Search backward for def test_*
  let l:line = search('^\s*def test_\w\+(', 'bcnW')
  if l:line == 0
    " Also try @pytest decorated functions
    let l:line = search('^\s*def test_\w\+(', 'bnW')
  endif
  " Restore cursor position
  call setpos('.', l:save_pos)
  if l:line == 0
    return ''
  endif
  " Extract function name
  let l:content = getline(l:line)
  let l:match = matchstr(l:content, 'def \zstest_\w\+\ze(')
  return l:match
endfunction

" Run the specific test at cursor
function! ProjectTestAtCursor()
  let l:test_name = GetTestFunctionAtCursor()
  if l:test_name == ''
    echo "No test function found at cursor"
    return
  endif
  let l:file = expand('%:p')
  if IsTritonProject()
    call SetPytestCompiler()
    execute 'Dispatch pytest --tb=short -xvs ' . shellescape(l:file . '::' . l:test_name)
  elseif IsIreeProject()
    execute "CMakeTest -R " . fnameescape(l:test_name) . " --output-on-failure -E 'cuda\|metal\|vulkan\|cpu\|e2e\|cts'"
  else
    echo "Unknown project type"
  endif
endfunction

" Project-aware test all (lit + cpp tests)
function! ProjectTestAll()
  if IsTritonProject()
    " Run both lit tests and C++ unit tests
    execute 'Dispatch make test-nogpu'
  elseif IsIreeProject()
    execute "CMakeTest all -j32 --output-on-failure -E 'cuda\|metal\|vulkan\|cpu\|e2e\|cts'"
  else
    echo "Unknown project type"
  endif
endfunction

nnoremap <leader>bb :call ProjectBuild()<CR>
nnoremap <leader>bc :call ProjectClean()<CR>
nnoremap <leader>tt :call ProjectTestFile()<CR>
nnoremap <leader>tu :call ProjectTestAtCursor()<CR>
nnoremap <leader>ta :call ProjectTestAll()<CR>

" IREE specific commands
nnoremap <leader>bt :CMakeBuild --target iree-test-deps<CR>
" This relies on export_iree_tools defined in ~/.zshrc
function! ExportIreeToolsFromShell()
  let output = system("zsh -c 'export_iree_tools; echo PATH=$PATH'")
  for line in split(output, "\n")
    if line =~ '^PATH='
      let $PATH = substitute(line, '^PATH=', '', '')
    endif
  endfor
endfunction
nnoremap <leader>bp :silent call ExportIreeToolsFromShell()<CR>

" Project-aware debug build
function! ProjectBuildDebug()
  if IsTritonProject()
    execute 'Dispatch DEBUG=1 pip install -e . --no-build-isolation'
  elseif IsIreeProject()
    silent CMakePreset dbg -Wno-dev
    call ExportIreeToolsFromShell()
  else
    echo "Unknown project type"
  endif
endfunction

" Project-aware release/model build
function! ProjectBuildRelease()
  if IsTritonProject()
    execute 'Dispatch pip install -e . --no-build-isolation'
  elseif IsIreeProject()
    silent CMakePreset model -Wno-dev
    call ExportIreeToolsFromShell()
  else
    echo "Unknown project type"
  endif
endfunction

nnoremap <leader>bd :call ProjectBuildDebug()<CR>
nnoremap <leader>bm :call ProjectBuildRelease()<CR>

" Note used cdna3 for simplicity. Needs to change label on different gpus
nnoremap <leader>tg :CMakeTest all --output-on-failure --label-regex '^requires-gpu-cdna3$\|^driver=hip$'<CR>

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
