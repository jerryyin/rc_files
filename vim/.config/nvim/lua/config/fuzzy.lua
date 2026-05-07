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

local function is_dir(path)
  return vim.fn.isdirectory(path) == 1
end

local function project_file_command(root)
  local base = [[(git ls-files --recurse-submodules 2>/dev/null; find build -name "*.inc" 2>/dev/null)]]
  local quoted_root = vim.fn.shellescape(root)

  if is_dir(root .. "/compiler/src/iree") or is_dir(root .. "/runtime/src/iree") then
    return (
      "cd %s && { "
      .. "git ls-files 2>/dev/null | grep -v '^third_party/'; "
      .. "git -C third_party/llvm-project ls-files mlir 2>/dev/null | sed 's#^#third_party/llvm-project/#'; "
      .. "find build -name \"*.inc\" 2>/dev/null; "
      .. "}"
    ):format(quoted_root)
  end

  if vim.fn.filereadable(root .. "/python/triton/__init__.py") == 1 or is_dir(root .. "/include/triton") then
    return ("cd %s && %s | grep -v -E '^third_party/(f2reduce|nvidia)/'"):format(quoted_root, base)
  end

  return ("cd %s && %s"):format(quoted_root, base)
end

function M.files()
  local root = git_root()
  local fzf = require("fzf-lua")
  local actions = require("fzf-lua.actions")
  local entries = vim.fn.systemlist(project_file_command(root))

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
