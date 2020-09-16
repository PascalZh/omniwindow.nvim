local M = {}
local api = vim.api
local menu_ui = require"menu_ui"

local terminal = {
  name = 'terminal',
  opts = {
    relative='editor', style='minimal',
    row=3, col=10, width=api.nvim_get_option("columns") - 20,
    height=30
  },
}
function terminal.cb_enter()
  if terminal.buf then
    terminal.window = api.nvim_open_win(terminal.buf, true, terminal.opts)
    vim.fn.execute("normal! i")
  else
    terminal.window = api.nvim_open_win(0, true, terminal.opts)
    vim.fn.execute("terminal")
    terminal.buf = vim.fn.winbufnr(0)
    api.nvim_buf_set_option(terminal.buf, 'buflisted', false)
  end
end
function terminal.cb_leave()
  if terminal.window then
    api.nvim_win_close(terminal.window, false)
  end
end

local foo = {
  name = 'foo',
  cb_enter = function() end,
  cb_leave = function() end,
}
--┌─────────────────────────────────────────────────────────┐
--│                         menu                            │
--└─────────────────────────────────────────────────────────┘
local items = {terminal, foo}
M.menu = menu_ui.create_menu({
  row = 2, col = 10, width = api.nvim_get_option("columns") - 20
}, items)

menu_ui.draw_menu(M.menu)

local function set_shift_item_keymap(keys, dir)
  for i, key in ipairs(keys) do
    api.nvim_buf_set_keymap(M.menu.buf, 'n', key,
    ':lua require"omniwindow".menu.shift_item('.. dir .. ')<cr>', {silent = true})
  end
end

set_shift_item_keymap({'h', 'j', 'b'}, 0)
set_shift_item_keymap({'l', 'k', 'e'}, 1)

function M.menu.shift_item(dir)
  menu_ui.shift_item(M.menu, dir)
end

function M.menu.toggle()
  menu_ui.toggle_menu(M.menu)
end

function M.menu.focus()
  api.nvim_set_current_win(M.menu.window)
end

return M
