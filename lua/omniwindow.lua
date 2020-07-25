local M = {}
local api = vim.api
local menu_ui = require"menu_ui"

local terminal = {
  name = 'terminal',
  buf = api.nvim_create_buf(false, true),
  opts = {
    relative='editor', style='minimal',
    row=3, col=10, width=api.nvim_get_option("columns") - 20,
    height=30
  },
}
function terminal.cb_enter()
  terminal.window = api.nvim_open_win(terminal.buf, true, terminal.opts)
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
local function create_menu()
  local items = {terminal, foo}
  local menu = menu_ui.create_menu({
    row = 2, col = 10, width = api.nvim_get_option("columns") - 20
  }, items)

  local function set_keymap(keys, dir)
    for i, key in ipairs(keys) do
      api.nvim_buf_set_keymap(menu.buf, 'n', key,
        ':lua require"omniwindow".menu.shift_item('.. dir .. ')<cr>', {silent = true})
    end
  end
  set_keymap({'h', 'j', 'b'}, 0)
  set_keymap({'l', 'k', 'e'}, 1)

  menu_ui.draw_menu(menu)

  function menu.shift_item(dir)
    menu_ui.shift_item(menu, dir)
  end

  function menu.toggle()
    menu_ui.toggle_menu(menu)
  end

  return menu
end

M.menu = create_menu()
return M
