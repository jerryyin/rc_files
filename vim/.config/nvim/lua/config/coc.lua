local M = {}

function M.setup()
  vim.g.coc_config_home = vim.fn.expand("~/.vim")
  vim.g.coc_global_extensions = { "coc-tsserver", "coc-json", "coc-pyright", "coc-snippets" }
  vim.g.coc_disable_startup_warning = 1

  if vim.fn.executable("/usr/bin/node") == 1 then
    vim.g.coc_node_path = "/usr/bin/node"
  end

  vim.fn.mkdir(vim.fn.expand("~/.cache"), "p")
  local localstorage = vim.fn.expand("~/.cache/coc-node-localstorage")
  if vim.fn.filereadable(localstorage) == 0 then
    vim.fn.writefile({}, localstorage)
  end
  vim.g.coc_node_args = { "--localstorage-file", localstorage }

  local function apply_highlights()
    for _, group in ipairs({ "CocInlayHint", "CocInlayHintType", "CocInlayHintParameter" }) do
      pcall(vim.api.nvim_set_hl, 0, group, { link = "Comment" })
    end
  end

  apply_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("NvimCocHighlights", { clear = true }),
    callback = apply_highlights,
  })

  local inlay_filetypes = {
    c = true,
    cc = true,
    cpp = true,
    cuda = true,
    mlir = true,
  }

  local function enable_inlay_hints(bufnr)
    if not vim.g.coc_service_initialized or not vim.api.nvim_buf_is_loaded(bufnr) then
      return
    end
    if not inlay_filetypes[vim.bo[bufnr].filetype] or vim.bo[bufnr].buftype ~= "" then
      return
    end
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_get_current_buf() == bufnr then
        pcall(vim.cmd, "CocCommand document.enableInlayHint")
      end
    end, 500)
  end

  local inlay_group = vim.api.nvim_create_augroup("NvimCocInlayHints", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = inlay_group,
    pattern = { "c", "cc", "cpp", "cuda", "mlir" },
    callback = function(args)
      enable_inlay_hints(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = inlay_group,
    callback = function(args)
      enable_inlay_hints(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = inlay_group,
    pattern = "CocNvimInit",
    callback = function()
      enable_inlay_hints(vim.api.nvim_get_current_buf())
    end,
  })

  local map = vim.keymap.set
  map("i", "<C-t>", "coc#refresh()", { expr = true, silent = true })
  map("i", "<CR>", [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]], {
    expr = true,
    silent = true,
  })

  map("n", "[g", "<Plug>(coc-diagnostic-prev)", { silent = true, remap = true })
  map("n", "]g", "<Plug>(coc-diagnostic-next)", { silent = true, remap = true })
  map("n", "gd", "<Plug>(coc-definition)", { silent = true, remap = true })
  map("n", "gy", "<Plug>(coc-type-definition)", { silent = true, remap = true })
  map("n", "gi", "<Plug>(coc-implementation)", { silent = true, remap = true })
  map("n", "gr", "<Plug>(coc-references)", { silent = true, remap = true })
  map("n", "<leader>cr", "<Plug>(coc-rename)", { silent = true, remap = true })
  map("n", "<leader>cf", "<Plug>(coc-fix-current)", { silent = true, remap = true })
  map("n", "<leader>ch", "<cmd>CocCommand document.toggleInlayHint<CR>", { silent = true })

  map("n", "K", function()
    if vim.fn.CocAction("hasProvider", "hover") then
      vim.fn.CocActionAsync("doHover")
    else
      vim.api.nvim_feedkeys("K", "in", false)
    end
  end, { silent = true })
end

return M
