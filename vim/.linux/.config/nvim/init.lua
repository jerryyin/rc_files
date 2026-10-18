local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
vim.opt.runtimepath:prepend(config_dir)
package.path = table.concat({
  config_dir .. "/lua/?.lua",
  config_dir .. "/lua/?/init.lua",
  package.path,
}, ";")

vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

require("config.options")
require("config.filetypes")
require("config.keymaps")
require("config.project")
require("config.tools")
if vim.env.NVIM_USE_NATIVE_LSP == "1" then
  require("config.lsp").setup()
end
require("config.lazy")
