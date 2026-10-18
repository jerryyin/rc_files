local M = {}

local function gruvbox_highlight(group, fg, bg, style)
  local ok = pcall(vim.fn["gruvbox_material#highlight"], group, fg, bg, style)
  if ok then
    return
  end

  local opts = {}
  if type(fg) == "table" and fg[1] and fg[1] ~= "NONE" then
    opts.fg = fg[1]
  end
  if type(bg) == "table" and bg[1] and bg[1] ~= "NONE" then
    opts.bg = bg[1]
  end
  if style == "underline" then
    opts.underline = true
  end
  vim.api.nvim_set_hl(0, group, opts)
end

function M.apply_custom_highlights()
  local ok_config, config = pcall(vim.fn["gruvbox_material#get_configuration"])
  if not ok_config then
    return
  end

  local ok_palette, palette = pcall(
    vim.fn["gruvbox_material#get_palette"],
    config.background,
    config.foreground,
    config.colors_override
  )
  if not ok_palette then
    return
  end

  gruvbox_highlight("DiffText", palette.none, palette.bg_visual_yellow)
  gruvbox_highlight("String", palette.purple, palette.none)
  gruvbox_highlight("CocSemTypeProperty", palette.aqua, palette.none, "underline")
  gruvbox_highlight("@property", palette.aqua, palette.none, "underline")
  gruvbox_highlight("debugPC", palette.none, palette.grey0)
end

function M.setup()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("NvimGruvboxMaterialCustom", { clear = true }),
    pattern = "gruvbox-material",
    callback = M.apply_custom_highlights,
  })

  local ok = pcall(vim.cmd.colorscheme, "gruvbox-material")
  if not ok then
    vim.cmd.colorscheme("default")
  end
end

return M
