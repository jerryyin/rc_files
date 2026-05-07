local M = {}

local function client_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  if ok then
    capabilities = cmp_lsp.default_capabilities(capabilities)
  end
  return capabilities
end

local function enable_inlay_hints(client, bufnr)
  if not (client.server_capabilities and client.server_capabilities.inlayHintProvider) then
    return
  end
  if not (vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable) then
    return
  end

  local ok = pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
  if not ok then
    pcall(vim.lsp.inlay_hint.enable, bufnr, true)
  end
end

local function schedule_inlay_hint_refresh(client, bufnr)
  for _, delay in ipairs({ 1000, 5000, 15000 }) do
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        enable_inlay_hints(client, bufnr)
      end
    end, delay)
  end
end

local function on_attach(client, bufnr)
  local function nmap(lhs, rhs)
    vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true })
  end

  nmap("[g", vim.diagnostic.goto_prev)
  nmap("]g", vim.diagnostic.goto_next)
  nmap("gd", vim.lsp.buf.definition)
  nmap("gy", vim.lsp.buf.type_definition)
  nmap("gi", vim.lsp.buf.implementation)
  nmap("gr", vim.lsp.buf.references)
  nmap("K", vim.lsp.buf.hover)
  nmap("<leader>cr", vim.lsp.buf.rename)
  nmap("<leader>cf", vim.lsp.buf.code_action)
  nmap("<leader>ch", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
  end)

  enable_inlay_hints(client, bufnr)
  schedule_inlay_hint_refresh(client, bufnr)
end

local function apply_semantic_highlight_links()
  local links = {
    ["@lsp.type.property.cpp"] = "@property",
    ["@lsp.type.parameter.cpp"] = "Identifier",
    ["@lsp.type.variable.cpp"] = "Identifier",
    ["@lsp.typemod.variable.classScope.cpp"] = "@property",
    ["@lsp.typemod.variable.functionScope.cpp"] = "Identifier",
    ["@lsp.typemod.variable.fileScope.cpp"] = "Constant",
    ["@lsp.typemod.variable.globalScope.cpp"] = "Constant",
    ["@lsp.typemod.variable.static.cpp"] = "Constant",
    ["@lsp.typemod.variable.readonly.cpp"] = "Constant",
    LspInlayHint = "Comment",
    InlayHints = "Comment",
  }

  for group, target in pairs(links) do
    pcall(vim.api.nvim_set_hl, 0, group, { link = target })
  end
end

local function setup_semantic_highlights()
  apply_semantic_highlight_links()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("NvimLspSemanticHighlights", { clear = true }),
    callback = apply_semantic_highlight_links,
  })
end

local function has_marker(dir, marker)
  local path = dir .. "/" .. marker
  return vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
end

local function root_pattern(markers, startpath)
  local dir = vim.fn.fnamemodify(startpath, ":p:h")
  while dir and dir ~= "/" and dir ~= "" do
    for _, marker in ipairs(markers) do
      if has_marker(dir, marker) then
        return dir
      end
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
  return vim.fn.getcwd()
end

local function start_server(bufnr, config)
  if vim.fn.executable(config.cmd[1]) ~= 1 then
    return
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  vim.lsp.start(vim.tbl_extend("force", config, {
    root_dir = config.root_dir or root_pattern(config.root_markers or { ".git" }, name),
    capabilities = client_capabilities(),
    on_attach = on_attach,
  }), { bufnr = bufnr })
end

local function setup_cmp()
  local ok, cmp = pcall(require, "cmp")
  if not ok then
    return
  end

  cmp.setup({
    completion = {
      keyword_length = 3,
      completeopt = "menu,menuone,noinsert",
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-t>"] = cmp.mapping.complete(),
      ["<CR>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.confirm({ select = true })
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<C-n>"] = cmp.mapping.select_next_item(),
      ["<C-p>"] = cmp.mapping.select_prev_item(),
      ["<C-e>"] = cmp.mapping.abort(),
    }),
    sources = cmp.config.sources({
      { name = "nvim_lsp" },
      { name = "path" },
      { name = "buffer", keyword_length = 3 },
    }),
  })
end

local function setup_servers()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("NvimNativeLsp", { clear = true }),
    pattern = { "c", "cc", "cpp", "c++", "cuda" },
    callback = function(args)
      start_server(args.buf, {
        name = "clangd",
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--all-scopes-completion",
          "--completion-style=detailed",
          "--header-insertion=iwyu",
          "--pch-storage=memory",
        },
        root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "compile_flags.txt", ".git" },
        settings = {
          clangd = {
            InlayHints = {
              Enabled = true,
              ParameterNames = true,
              DeducedTypes = true,
              Designators = true,
              DefaultArguments = true,
              TypeNameLimit = 0,
            },
          },
        },
      })
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("NvimNativeMlirLsp", { clear = true }),
    pattern = "mlir",
    callback = function(args)
      start_server(args.buf, {
        name = "mlir-lsp",
        cmd = { "mlir-lsp" },
        root_markers = { "python/triton/__init__.py", "include/triton", "compiler/src/iree", "runtime/src/iree", ".git" },
      })
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("NvimNativePyright", { clear = true }),
    pattern = "python",
    callback = function(args)
      start_server(args.buf, {
        name = "pyright",
        cmd = { "pyright-langserver", "--stdio" },
        root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "off",
            },
          },
        },
      })
    end,
  })
end

function M.setup()
  for type, text in pairs({ Error = "E", Warn = "W", Info = "I", Hint = "H" }) do
    vim.fn.sign_define("DiagnosticSign" .. type, {
      text = text,
      texthl = "DiagnosticSign" .. type,
      numhl = "",
    })
  end

  vim.diagnostic.config({
    virtual_text = true,
    underline = true,
    severity_sort = true,
    signs = true,
  })

  setup_semantic_highlights()
  setup_cmp()
  setup_servers()
end

return M
