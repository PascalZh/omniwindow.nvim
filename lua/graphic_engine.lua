local M = {}
local api = vim.api

function M.draw_single_color(lines, ns)
  ns = ns or api.nvim_create_namespace('DrawHighlights')
  for i, line in ipairs(lines) do
    api.nvim_buf_set_virtual_text(0, ns, i - 1, {{line, 'Function'}}, {})
  end
  return ns
end

return M
