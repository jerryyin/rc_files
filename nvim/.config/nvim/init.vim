" Active Neovim entrypoint.
"
" The migrated config lives with the Vim package so stow can install both Vim
" and Neovim editor configs from the same package.
lua dofile(vim.fn.expand('~/rc_files/vim/.config/nvim/init.lua'))
