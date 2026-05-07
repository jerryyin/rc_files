if vim.env.NVIM_SKIP_PLUGINS == "1" then
  return
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "sainnhe/gruvbox-material",
    priority = 1000,
    config = function()
      require("config.theme").setup()
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "gruvbox-material",
          icons_enabled = false,
          component_separators = "",
          section_separators = "",
        },
        sections = {
          lualine_b = { "branch", "diff" },
          lualine_c = { "filename", _G.NearestMethodOrFunction },
          lualine_x = { "encoding", "fileformat", "filetype" },
        },
      })
    end,
  },
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      vim.opt.showtabline = 2
      require("bufferline").setup({
        options = {
          mode = "buffers",
          sort_by = "recently_used",
          show_buffer_icons = false,
          show_close_icon = false,
          show_buffer_close_icons = false,
          show_tab_indicators = false,
          separator_style = "thin",
          always_show_bufferline = true,
          diagnostics = false,
          offsets = {},
        },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    cond = vim.fn.has("nvim-0.10") == 1,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
        indent = { enable = true },
        auto_install = false,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    cond = vim.fn.has("nvim-0.10") == 1,
    config = true,
  },
  {
    "ibhagwan/fzf-lua",
    dependencies = {
      { "junegunn/fzf", build = "./install --bin" },
    },
    config = function()
      require("config.fuzzy").setup()
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
    },
    config = function()
      require("config.lsp").setup()
    end,
  },
  {
    "stevearc/conform.nvim",
    cond = vim.fn.has("nvim-0.10") == 1,
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        cpp = { "clang_format" },
        c = { "clang_format" },
        cuda = { "clang_format" },
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    config = true,
  },
  {
    "stevearc/oil.nvim",
    opts = {
      default_file_explorer = true,
      view_options = {
        show_hidden = true,
      },
    },
  },
  { "windwp/nvim-autopairs", config = true },
  { "numToStr/Comment.nvim", config = true },
  { "chentoast/marks.nvim", config = true },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = { char = "|" },
      scope = { enabled = false },
    },
  },
  {
    "echasnovski/mini.starter",
    cond = vim.fn.has("nvim-0.10") == 1,
    config = function()
      require("mini.starter").setup()
    end,
  },

  -- Workflow-specific Vim plugins kept while native equivalents settle.
  { "tpope/vim-fugitive" },
  { "tpope/vim-dispatch" },
  { "tpope/vim-rsi" },
  { "tpope/vim-surround" },
  { "tpope/vim-unimpaired" },
  { "tpope/vim-apathy" },
  { "tpope/vim-eunuch" },
  { "aymericbeaumet/vim-symlink" },
  { "jerryyin/vim-mlirtools" },
  { "ericcurtin/CurtineIncSw.vim" },
  { "ojroques/vim-oscyank", branch = "main" },
  { "wellle/targets.vim" },
  { "AndrewRadev/splitjoin.vim" },
  { "github/copilot.vim" },
  { "ludovicchabant/vim-gutentags" },
  { "pseewald/vim-anyfold" },
  { "simeji/winresizer" },
  { "Makaze/AnsiEsc" },
  { "llvm/llvm.vim" },
  { "vim-pandoc/vim-pandoc-syntax" },
}, {
  root = vim.fn.stdpath("data") .. "/lazy",
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  change_detection = {
    notify = false,
  },
})
