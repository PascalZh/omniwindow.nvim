local M = {}
M.win = {}
function M.win.float(height, width, row, col)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, { relative='editor',
      width=width, height=height, row=row, col=col,
      focusable=false, style='minimal',
    })
  return {buf, win}
end

return M
