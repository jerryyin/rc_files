local M = {}

local function conform_format(opts)
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format(vim.tbl_extend("force", { async = true, lsp_fallback = true }, opts or {}))
    return
  end

  if vim.lsp.buf.format then
    vim.lsp.buf.format(vim.tbl_extend("force", { async = true }, opts or {}))
  end
end

function M.buffer()
  conform_format()
end

function M.visual()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  conform_format({
    range = {
      start = { start_pos[2], start_pos[3] - 1 },
      ["end"] = { end_pos[2], end_pos[3] },
    },
  })
end

function M.current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  conform_format({
    range = {
      start = { row, 0 },
      ["end"] = { row, math.max(vim.fn.col("$") - 1, 0) },
    },
  })
end

function M.to_eof()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  conform_format({
    range = {
      start = { row, 0 },
      ["end"] = { vim.api.nvim_buf_line_count(0), 0 },
    },
  })
end

return M
