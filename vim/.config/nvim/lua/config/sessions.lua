local M = {}

local session_dir = vim.fn.stdpath("data") .. "/sessions"

local function default_session()
  return vim.fn.fnamemodify(vim.fn.getcwd(), ":t") .. ".vim"
end

local function session_path(name)
  return session_dir .. "/" .. name
end

function M.save(name)
  name = name or default_session()
  vim.fn.mkdir(session_dir, "p")
  vim.cmd("mksession! " .. vim.fn.fnameescape(session_path(name)))
end

function M.load(name)
  name = name or default_session()
  vim.cmd("source " .. vim.fn.fnameescape(session_path(name)))
end

function M.delete(name)
  name = name or default_session()
  local path = session_path(name)
  if vim.fn.filereadable(path) == 1 then
    vim.fn.delete(path)
  end
end

function M.default_session()
  return default_session()
end

function M.setup()
  vim.api.nvim_create_user_command("SSave", function(opts)
    M.save(opts.args ~= "" and opts.args or nil)
  end, { nargs = "?" })
  vim.api.nvim_create_user_command("SLoad", function(opts)
    M.load(opts.args ~= "" and opts.args or nil)
  end, { nargs = "?" })
  vim.api.nvim_create_user_command("SDelete", function(opts)
    M.delete(opts.args ~= "" and opts.args or nil)
  end, { nargs = "?" })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("NvimDefaultSession", { clear = true }),
    nested = true,
    callback = function()
      local path = session_path(default_session())
      if vim.fn.argc() == 0 and vim.v.this_session == "" and vim.bo.modified == false and vim.fn.filereadable(path) == 0 then
        M.save()
      end
    end,
  })

  vim.keymap.set("n", "<leader>sl", function()
    M.load()
  end, { silent = true })
  vim.keymap.set("n", "<leader>sv", function()
    M.save()
  end, { silent = true })
  vim.keymap.set("n", "<leader>sd", function()
    M.delete()
  end, { silent = true })
end

return M
