set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath                                           
source ~/.vimrc

call plug#begin('~/.config/nvim/plugged')
Plug 'nvim-lua/plenary.nvim'
Plug 'CopilotC-Nvim/CopilotChat.nvim', { 'branch': 'canary' }
call plug#end()

lua << EOF
require("CopilotChat").setup {
  show_help = 'yes',
  debug = false,
  disable_extra_info = 'no',
  language = 'English'
}
EOF

" Key mappings for CopilotChat
nmap <leader>ce :CopilotChatExplain<cr>
nmap <leader>ct :CopilotChatTests<cr>
nmap <leader>cr :CopilotChatReview<cr>
nmap <leader>cf :CopilotChatFix<cr>
nmap <leader>cd :CopilotChatDocs<cr>
nmap <leader>cc :CopilotChatCommit<cr>
