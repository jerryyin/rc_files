local M = {}

local map = vim.keymap.set
local g = vim.g

g.gutentags_generate_on_new = 1
g.gutentags_generate_on_missing = 1
g.gutentags_generate_on_write = 1
g.gutentags_generate_on_empty_buffer = 0
g.gutentags_project_root = { ".root", ".svn", ".git", ".hg", ".project" }
g.gutentags_ctags_tagfile = ".tags"
g.gutentags_cache_dir = vim.fn.stdpath("cache") .. "/gutentags"
vim.fn.mkdir(g.gutentags_cache_dir, "p")
g.gutentags_modules = vim.fn.executable("ctags") == 1 and { "ctags" } or {}

g.tmuxline_powerline_separators = 0
g.termdebug_config = {
  disasm_window = false,
  variables_window = false,
  evaluate_in_popup = true,
  map_K = false,
}

function _G.NearestMethodOrFunction()
  return vim.b.vista_nearest_method_or_function or ""
end

vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("NvimFugitiveDeleteBuffer", { clear = true }),
  pattern = "fugitive://*",
  callback = function()
    vim.bo.bufhidden = "delete"
  end,
})

local function toggle_git_status()
  for winnr = 1, vim.fn.winnr("$") do
    if vim.fn.getwinvar(winnr, "fugitive_status") ~= "" then
      vim.cmd(winnr .. "close")
      return
    end
  end
  vim.cmd("Git")
  vim.cmd("10wincmd _")
end

local function git_clang_format_here()
  local bufdir = vim.fn.expand("%:p:h")
  local root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(bufdir) .. " rev-parse --show-toplevel")
  if vim.v.shell_error ~= 0 or #root == 0 then
    vim.notify("Not a git repo", vim.log.levels.WARN)
    return
  end
  local cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(root[1]))
  vim.cmd("Git clang-format")
  vim.cmd("cd " .. vim.fn.fnameescape(cwd))
end

map("n", "<leader>gg", toggle_git_status, { silent = true })
map("n", "<leader>gb", "<cmd>Git blame<CR>", { silent = true })
map("n", "<leader>gc", "<cmd>Git commit<CR>", { silent = true })
map("n", "<leader>gd", "<cmd>Gvdiffsplit<CR>", { silent = true })
map("n", "<leader>gf", git_clang_format_here, { silent = true })
map("n", "<leader>gp", "<cmd>Git pull --rebase<CR>", { silent = true })
map("n", "<leader>gl", "<cmd>Gclog<CR>", { silent = true })
map("n", "<leader>gw", "<cmd>Gwrite<CR>", { silent = true })
map("n", "<leader>gr", "<cmd>Gread<CR>", { silent = true })

map("n", "<leader>yy", "<Plug>OSCYankOperator")
map("v", "<leader>y", "<Plug>OSCYankVisual")

map("x", "<leader>ty", function()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  vim.fn.system("tmux load-buffer -", table.concat(lines, "\n"))
  vim.cmd("normal! gv")
end, { silent = true })

map("n", "<leader>tp", function()
  local text = vim.fn.system("tmux save-buffer -")
  vim.api.nvim_put(vim.split(text, "\n", { plain = true }), "l", true, true)
end, { silent = true })

local function adjust_debug_layout()
  local layout = vim.fn.winlayout()
  local full_height = vim.o.lines
  if layout[1] ~= "col" then
    return
  end

  local num_panes = #layout[2]
  local source_ratio = num_panes == 2 and 0.8 or 0.7
  local gdb_ratio = 0.2
  vim.cmd("wincmd t")
  vim.cmd("resize " .. math.floor(full_height * source_ratio))
  vim.cmd("wincmd j")
  vim.cmd("resize " .. math.floor(full_height * gdb_ratio))
end

local dbg_loaded = false
local function run_termdebug(opts)
  if not dbg_loaded then
    pcall(vim.cmd, "packadd termdebug")
    dbg_loaded = true
  end
  vim.cmd("wincmd H")
  vim.cmd("TermdebugCommand " .. opts.args)
  vim.cmd("wincmd J")
  vim.cmd("wincmd k")
  vim.cmd("wincmd J")
  adjust_debug_layout()
end

vim.api.nvim_create_user_command("Dbg", run_termdebug, { nargs = "*" })
map("n", "<Leader>dl", adjust_debug_layout, { silent = true })
map("n", "E", "<cmd>Evaluate<CR>", { silent = true })
map("n", "J", "<cmd>Over<CR>", { silent = true })
map("n", "S", "<cmd>Step<CR>", { silent = true })
map("n", "B", "<cmd>Break<CR>", { silent = true })
map("n", "D", "<cmd>Clear<CR>", { silent = true })
map("n", "C", "<cmd>Continue<CR>", { silent = true })

local function paste_to_claude_tmux(text)
  local temp = vim.fn.tempname()
  vim.fn.writefile(vim.split(text, "\n", { plain = true }), temp)
  vim.fn.system("tmux load-buffer " .. vim.fn.shellescape(temp))
  vim.fn.system("tmux paste-buffer -t {last}")
  vim.fn.delete(temp)
end

function _G.SendToClaudeVisual()
  if vim.env.TMUX == nil or vim.env.TMUX == "" then
    vim.notify("Error: Not in tmux", vim.log.levels.ERROR)
    return
  end

  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local filename = vim.fn.expand("%:t")
  local text = ("File: %s (lines %d-%d)\n\n%s"):format(filename, start_line, end_line, table.concat(lines, "\n"))
  paste_to_claude_tmux(text)
  vim.notify(("Pasted to Claude: %s (lines %d-%d)"):format(filename, start_line, end_line))
end

function _G.SendToClaudeBuffer()
  if vim.env.TMUX == nil or vim.env.TMUX == "" then
    vim.notify("Error: Not in tmux", vim.log.levels.ERROR)
    return
  end

  local text = vim.fn.expand("%:p") .. ":" .. vim.fn.line(".")
  paste_to_claude_tmux(text)
  vim.notify("Pasted to Claude: " .. text)
end

map("x", "<leader>cc", _G.SendToClaudeVisual, { silent = true })
map("n", "<leader>cc", _G.SendToClaudeBuffer, { silent = true })

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  group = vim.api.nvim_create_augroup("NvimLightAutosave", { clear = true }),
  callback = function(args)
    local bo = vim.bo[args.buf]
    if bo.modified and bo.modifiable and bo.buftype == "" and vim.api.nvim_buf_get_name(args.buf) ~= "" then
      pcall(vim.cmd, "silent write")
    end
  end,
})

require("config.sessions").setup()

return M
