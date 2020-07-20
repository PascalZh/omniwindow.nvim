local M = {}
local api = vim.api
local menu_ui = require"menu_ui"
--┌─────────────────────────────────────────────────────────┐
--│                         api                             │
--└─────────────────────────────────────────────────────────┘
local function create_menu()
  local menu = menu_ui.create_menu(nil, {
    row = 2, col = 10, width = api.nvim_get_option("columns") - 20
  })

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
    menu_ui.shift_item(menu, 0)
    menu_ui.shift_item(menu, 1)
  end

  return menu
end

M.menu = create_menu()
return M
