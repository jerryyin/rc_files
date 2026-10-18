local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

vim.g.LargeFile = 1000000

vim.filetype.add({
  extension = {
    mlir = "mlir",
    cu = "cuda",
    dockerfile = "dockerfile",
    ttir = "mlir",
    ttgir = "mlir",
    llir = "llvm",
    amdgcn = "asm",
  },
  pattern = {
    [".*%.inc"] = function()
      vim.bo.syntax = "cpp"
    end,
  },
})

local large_file_group = augroup("NvimLargeFile", { clear = true })
autocmd("BufReadPre", {
  group = large_file_group,
  callback = function(args)
    local size = vim.fn.getfsize(args.file)
    if size > vim.g.LargeFile or size == -2 then
      vim.b[args.buf].large_file = true
    end
  end,
})

autocmd("BufReadPost", {
  group = large_file_group,
  callback = function(args)
    if vim.b[args.buf].large_file then
      vim.bo[args.buf].foldmethod = "indent"
    end
  end,
})

local ft_group = augroup("NvimFiletypeSettings", { clear = true })
autocmd("FileType", {
  group = ft_group,
  pattern = "qf",
  callback = function()
    vim.opt_local.wrap = true
    pcall(vim.cmd, "AnsiEsc")
  end,
})

autocmd("FileType", {
  group = ft_group,
  pattern = "*",
  callback = function(args)
    if vim.bo[args.buf].buftype == "" then
      vim.opt_local.spell = true
    end
  end,
})

autocmd("FileType", {
  group = ft_group,
  pattern = "mlir",
  callback = function()
    vim.opt_local.iskeyword:append("%")
  end,
})

autocmd("FileType", {
  group = ft_group,
  pattern = "pov",
  callback = function()
    vim.bo.syntax = "cpp"
  end,
})

autocmd("FileType", {
  group = augroup("NvimAnyFold", { clear = true }),
  pattern = "cpp",
  callback = function(args)
    if not vim.b[args.buf].large_file and vim.fn.exists(":AnyFoldActivate") == 2 then
      vim.cmd("AnyFoldActivate")
    end
  end,
})
