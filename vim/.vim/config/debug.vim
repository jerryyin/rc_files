" Session-only debugger mappings shared by Vim and Neovim.
let s:bindings = {'E': 'Evaluate', 'J': 'Over', 'S': 'Step', 'B': 'Break', 'D': 'Clear', 'C': 'Continue'}
let s:saved = get(s:, 'saved', {})

function! s:StartMappings() abort
  if !empty(s:saved)
    return
  endif
  let l:maps = filter(maplist(), '!v:val.buffer && v:val.mode =~# "[n ]"')
  for [l:key, l:command] in items(s:bindings)
    let s:saved[l:key] = get(filter(copy(l:maps), 'v:val.lhs ==# l:key'), 0, {})
    execute 'nnoremap <silent> ' . l:key . ' :' . l:command . '<CR>'
  endfor
endfunction

function! s:StopMappings() abort
  for [l:key, l:mapping] in items(s:saved)
    execute 'silent! nunmap ' . l:key
    if !empty(l:mapping)
      call mapset('n', 0, l:mapping)
    endif
  endfor
  let s:saved = {}
endfunction

augroup PersonalDebugMappings
  autocmd!
  autocmd User TermdebugStartPost call s:StartMappings()
  autocmd User TermdebugStopPost call s:StopMappings()
augroup END
