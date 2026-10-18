local map = vim.keymap.set

map({ "n", "v" }, "<C-J>", "<C-W>j", { silent = true })
map({ "n", "v" }, "<C-K>", "<C-W>k", { silent = true })
map({ "n", "v" }, "<C-H>", "<C-W>h", { silent = true })
map({ "n", "v" }, "<C-L>", "<C-W>l", { silent = true })
map("t", "<C-h>", [[<C-\><C-n><C-w>h]], { silent = true })
map("t", "<C-j>", [[<C-\><C-n><C-w>j]], { silent = true })
map("t", "<C-k>", [[<C-\><C-n><C-w>k]], { silent = true })
map("t", "<C-l>", [[<C-\><C-n><C-w>l]], { silent = true })
map("t", "<Esc>", [[<C-\><C-n>]], { silent = true })

vim.api.nvim_create_user_command("Bterm", function()
  vim.cmd("botright 15split | terminal")
end, {})
vim.cmd([[cnoreabbrev <expr> bterm getcmdtype() ==# ':' && getcmdline() ==# 'bterm' ? 'Bterm' : 'bterm']])

map("n", "<tab>", "<C-W><C-W>", { silent = true })
map("n", "<F12>", function()
  local line = vim.fn.line(".")
  local col = vim.fn.col(".")
  local hi = vim.fn.synIDattr(vim.fn.synID(line, col, 1), "name")
  local trans = vim.fn.synIDattr(vim.fn.synID(line, col, 0), "name")
  local lo = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.synID(line, col, 1)), "name")
  print(("hi<%s> trans<%s> lo<%s>"):format(hi, trans, lo))
end, { silent = true })

map("n", "<leader>qo", function()
  vim.cmd("copen")
  vim.cmd("10wincmd _")
end, { silent = true })
map("n", "<leader>qc", "<cmd>cclose<CR>", { silent = true })
map("n", "<leader>ea", "<cmd>AnsiEsc<CR>", { silent = true })

map("x", "=", function()
  require("config.format").visual()
end, { silent = true })
map("n", "=G", function()
  require("config.format").to_eof()
end, { silent = true })
map("n", "==", function()
  require("config.format").current_line()
end, { silent = true })
map("n", "=%", function()
  require("config.format").buffer()
end, { silent = true })

map("n", "<leader>fn", "<cmd>Oil<CR>", { silent = true })
map("n", "-", function()
  local name = vim.api.nvim_buf_get_name(0)
  local dir
  if name == "" or name:match("^term://") then
    dir = "."
  else
    dir = vim.fn.fnamemodify(name, ":p:h")
  end
  vim.cmd.edit(vim.fn.fnameescape(dir))
end, { silent = true })

map("n", "<C-e>", "<C-^>", { silent = true })
map("n", "<C-s>", function()
  if vim.v.count > 0 then
    vim.cmd(("vert belowright sb %d"):format(vim.v.count))
  else
    vim.cmd("vert belowright sb")
  end
end, { silent = true })
map("n", "<Leader>a", function()
  if vim.fn.exists("*CurtineIncSw") == 1 then
    vim.fn.CurtineIncSw()
  end
end, { silent = true })
