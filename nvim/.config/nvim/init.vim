set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath                                           
source ~/.vimrc
" Macos: point to system python3 that has pynvim installed
let g:python3_host_prog = '/usr/bin/python3'

call plug#begin('~/.config/nvim/plugged')
Plug 'nvim-lua/plenary.nvim'
Plug 'CopilotC-Nvim/CopilotChat.nvim', { 'branch': 'main' }
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
call plug#end()

lua << EOF
require("CopilotChat").setup {
  show_help = 'yes',
  debug = false,
  disable_extra_info = 'no',
  language = 'English'
}

require'nvim-treesitter.configs'.setup {
  ensure_installed = {"cpp", "c", "cuda", "vim", "markdown", "python"},
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}
vim.api.nvim_set_hl(0, '@variable.parameter.cpp', { bold = true })
vim.api.nvim_set_hl(0, '@variable.member.cpp', { italic = true })

EOF

" Key mappings for CopilotChat
nmap <leader>ce :CopilotChatExplain<cr>
nmap <leader>ct :CopilotChatTests<cr>
nmap <leader>cr :CopilotChatReview<cr>
nmap <leader>cf :CopilotChatFix<cr>
nmap <leader>cd :CopilotChatDocs<cr>
nmap <leader>cc :CopilotChatCommit<cr>
