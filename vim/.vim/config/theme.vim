" Theme and color-related settings.

set background=dark
if has("termguicolors") && $TERM =~ "256color" &&
  \ ($COLORTERM =~ "truecolor" || !empty($TMUX))
    " Terminal supports True Color
    set termguicolors
else
    " Fall back to 256 colors
    set notermguicolors
endif

" Undercurl
let &t_Cs = "\e[4:3m"
" Underdouble
let &t_Us = "\e[4:2m"
" Underdotted
let &t_ds = "\e[4:4m"
" Underdashed
let &t_Ds = "\e[4:5m"
" Reset
let &t_Ce = "\e[4:0m"

" This configuration option should be placed before `colorscheme gruvbox-material`.
" Available values: 'hard', 'medium'(default), 'soft'
let g:gruvbox_material_background = 'hard'
let g:gruvbox_material_ui_contrast = 'high'
let g:gruvbox_material_transparent_background = 2
let g:gruvbox_material_enable_bold = 1
let g:gruvbox_material_enable_italic = 1
let g:gruvbox_material_diagnostic_text_highlight = 1
" highlight error/warning/info hint lines
let g:gruvbox_material_diagnostic_virtual_text = 'colored'
" For better performance
let g:gruvbox_material_better_performance = 1
function! s:gruvbox_material_custom() abort
  let l:config = gruvbox_material#get_configuration()
  let l:palette = gruvbox_material#get_palette(l:config.background, l:config.foreground, l:config.colors_override)

  " Keep intraline diff changes visible without replacing syntax colors.
  call gruvbox_material#highlight('DiffText', l:palette.none, l:palette.bg_visual_yellow)
  call gruvbox_material#highlight('String', l:palette.purple, l:palette.none)
  " CocCommand semanticTokens.inspect
  call gruvbox_material#highlight('CocSemTypeProperty', l:palette.aqua, l:palette.none, 'underline')
  call gruvbox_material#highlight('debugPC', l:palette.none, l:palette.grey0)
endfunction

augroup GruvboxMaterialCustom
  autocmd!
  autocmd ColorScheme gruvbox-material call s:gruvbox_material_custom()
augroup END
colorscheme gruvbox-material

" lightline
" Customize colorscheme, branch and tabline
set showtabline=2
set laststatus=2
set noshowmode
let g:lightline = {
  \ 'colorscheme': 'gruvbox_material',
  \ 'active': {
  \   'left': [['mode', 'paste'],
  \            ['gitbranch', 'readonly', 'modified', 'filename', 'method']],
  \   'right': [['lineinfo'], ['percent'], ['filetype']]
  \ },
  \ 'component_function': {
  \   'gitbranch': 'FugitiveHead',
  \   'method': 'NearestMethodOrFunction'
  \ },
  \ 'tabline': {
  \   'left': [ [ 'mrubuffers' ] ],
  \   'right': [ [ 'tabnum' ] ]
  \ },
  \ 'tabline_subseparator': { 'left': '', 'right': ''  },
  \ 'component_expand': {
  \   'mrubuffers': 'bufmru#lightline#buffers',
  \   'tabnum': 'bufmru#lightline#tabnum',
  \ },
  \ 'component_type': {
  \   'buffers':       'tabsel',
  \   'mrubuffers':    'tabsel',
  \ },
  \ 'component_raw': {
  \   'mrubuffers':     1,
  \   'tabnum':         1,
  \ },
  \ 'enable': {
  \   'statusline': 1,
  \   'tabline': 1
  \ }
\ }

let g:ansi_Black = '#1d2021'
let g:ansi_DarkRed = '#cc241d'
let g:ansi_DarkGreen = '#98971a'
let g:ansi_DarkYellow = '#d79921'
let g:ansi_DarkBlue = '#458588'
let g:ansi_DarkMagenta = '#b16286'
let g:ansi_DarkCyan = '#689d6a'
let g:ansi_LightGray = '#ebdbb2'
let g:ansi_DarkGray = '#a89984'

let g:tmuxline_powerline_separators = 0
