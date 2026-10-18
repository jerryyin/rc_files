local M = {}

local function git_root()
  local bufdir = vim.fn.expand("%:p:h")
  if bufdir == "" then
    bufdir = vim.fn.getcwd()
  end
  local root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(bufdir) .. " rev-parse --show-toplevel")
  if vim.v.shell_error == 0 and root[1] and root[1] ~= "" then
    return root[1]
  end
  return vim.fn.getcwd()
end

function M.files()
  local root = git_root()
  local fzf = require("fzf-lua")
  local actions = require("fzf-lua.actions")
  local entries = vim.fn.systemlist({ "python3", vim.fn.expand("~/.vim/config/project-files.py"), root })

  if vim.v.shell_error ~= 0 then
    vim.notify("File picker source command failed", vim.log.levels.ERROR)
    return
  end

  fzf.fzf_exec(entries, {
    cwd = root,
    prompt = "Files> ",
    actions = {
      ["enter"] = actions.file_edit_or_qf,
      ["ctrl-s"] = actions.file_split,
      ["ctrl-v"] = actions.file_vsplit,
      ["ctrl-t"] = actions.file_tabedit,
    },
    fzf_opts = {
      ["--multi"] = true,
    },
  })
end

function M.buffers()
  require("fzf-lua").buffers({
    prompt = "Buffers> ",
  })
end

function M.grep()
  require("fzf-lua").live_grep({
    cwd = git_root(),
    rg_opts = "--column --line-number --no-heading --color=always --smart-case --glob '!build/**'",
  })
end

function M.grep_cword()
  require("fzf-lua").grep_cword({
    cwd = git_root(),
    rg_opts = "--column --line-number --no-heading --color=always --smart-case --glob '!build/**'",
  })
end

function M.setup()
  local fzf_bin_dir = vim.fn.stdpath("data") .. "/lazy/fzf/bin"
  if vim.fn.isdirectory(fzf_bin_dir) == 1 then
    vim.env.PATH = fzf_bin_dir .. ":" .. (vim.env.PATH or "")
  end

  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    return
  end

  fzf.setup({
    winopts = {
      height = 0.30,
      width = 0.30,
      preview = { hidden = "hidden" },
    },
    files = {
      git_icons = false,
      file_icons = false,
    },
  })

  vim.keymap.set("n", "<leader>ff", M.files, { silent = true })
  vim.keymap.set("n", "<leader>fb", M.buffers, { silent = true })
  vim.keymap.set("n", "<leader>ss", M.grep, { silent = true })
  vim.keymap.set("n", "<leader>sg", M.grep_cword, { silent = true })
  vim.keymap.set("n", "<leader>sa", M.grep_cword, { silent = true })
end

return M
