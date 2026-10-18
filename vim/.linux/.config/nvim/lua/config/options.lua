local opt = vim.opt
local g = vim.g

opt.history = 10000
opt.clipboard = "unnamed"
opt.wrap = true
opt.display = "lastline"
opt.wildmenu = true
opt.wildmode = { "list:longest", "full" }
opt.nrformats:remove("octal")
opt.linebreak = true
opt.foldlevel = 2
opt.shiftwidth = 2
opt.tabstop = 2
opt.expandtab = true
opt.softtabstop = -1
opt.encoding = "utf-8"
opt.autoindent = true
opt.smarttab = true

opt.mouse = "a"
opt.shortmess = "a"
opt.showmode = false
opt.showcmd = true
opt.cursorline = true
opt.ruler = true
opt.splitbelow = true
opt.splitright = true

opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.showmatch = true
opt.backspace = { "indent", "eol", "start" }
opt.autoread = true
opt.hidden = true
opt.timeoutlen = 1000
opt.ttimeoutlen = 0
opt.number = true
opt.relativenumber = true
opt.background = "dark"
opt.shellpipe = "2>&1|tee"
opt.guicursor = "n-v-c:block-blinkon0,o:hor50-blinkon0,i-ci:hor15-blinkon0,r-cr:hor30-blinkon0,sm:block-blinkon0"

local term = vim.env.TERM or ""
local colorterm = vim.env.COLORTERM or ""
if vim.fn.has("termguicolors") == 1 and term:match("256color") and (colorterm:match("truecolor") or vim.env.TMUX) then
  opt.termguicolors = true
else
  opt.termguicolors = false
end

vim.cmd("filetype plugin indent on")
vim.cmd("syntax on")

g.gruvbox_material_background = "hard"
g.gruvbox_material_ui_contrast = "high"
g.gruvbox_material_transparent_background = 2
g.gruvbox_material_enable_bold = 1
g.gruvbox_material_enable_italic = 1
g.gruvbox_material_diagnostic_text_highlight = 1
g.gruvbox_material_diagnostic_virtual_text = "colored"
g.gruvbox_material_better_performance = 1

g.context_highlight_tag = "<hide>"
g.context_add_mappings = 0
g.cpp_class_scope_highlight = 1
g.cpp_member_variable_highlight = 1
g.cpp_class_decl_highlight = 1
g.dispatch_no_maps = 1
g.dispatch_no_job_make = 1

g.winresizer_start_key = "<C-t>"
g.winresizer_finish_with_escape = 1
g.AutoPairsFlyMode = 0
g.SignaturePeriodicRefresh = 0

g.ansi_Black = "#1d2021"
g.ansi_DarkRed = "#cc241d"
g.ansi_DarkGreen = "#98971a"
g.ansi_DarkYellow = "#d79921"
g.ansi_DarkBlue = "#458588"
g.ansi_DarkMagenta = "#b16286"
g.ansi_DarkCyan = "#689d6a"
g.ansi_LightGray = "#ebdbb2"
g.ansi_DarkGray = "#a89984"
