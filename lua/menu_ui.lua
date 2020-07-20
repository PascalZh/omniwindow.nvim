local M = {}
local api = vim.api

function M.create_menu(items, args)
  local menu = {
    buf = api.nvim_create_buf(false, true),
    opts = {
      relative='editor', style='minimal',
      row=args.row, col=args.col, width=args.width, height=1
    },
    items = items or {
      {
        name = 'foo',
        callback = function() end,

        next_items = {
          {
            name = 'foobar',
            callback = function() end
          }
        }
      },
      {
        name = 'bar',
        callback = function() return "foobar" end,

        next_items = nil
      }
    },
    idx = 1
  }

  menu.pItems = menu.items
  menu.ns = api.nvim_create_namespace('MenuUIHighlights')

  api.nvim_buf_set_option(menu.buf, 'modifiable', false)
  return menu
end

function M.is_menu_open(menu)
  return menu.window and vim.fn.bufwinid(menu.buf) == menu.window
end

function M.is_menu_closed(menu)
  return not menu.window or vim.fn.winbufnr(menu.window) ~= menu.buf
end

function M.open_menu(menu, enter)
  if (M.is_menu_open(menu)) then
    do return end
  end
  menu.window = api.nvim_open_win(menu.buf, enter or true, menu.opts)
end

function M.close_menu(menu)
  if (M.is_menu_closed(menu)) then
    do return end
  end
  api.nvim_win_close(menu.window, false)
  menu.window = nil
end

function M.toggle_menu(menu)
  if (M.is_menu_closed(menu)) then
    M.open_menu(menu, true)
  elseif (M.is_menu_open(menu)) then
    M.close_menu(menu)
  else
    error("menu is not open and closed!")
  end
end

--┌─────────────────────────────────────────────────────────────┐
--│                           ui                                │
--└─────────────────────────────────────────────────────────────┘
function M.draw_menu(menu)
  if not menu.pItems then
    do return end
  end
  local lines = { "" }
  for idx,val in ipairs(menu.pItems) do
    lines[1] = lines[1] .. " " .. val.name
  end
  api.nvim_buf_set_lines(menu.buf, 0, 1, false, lines)

  api.nvim_buf_clear_namespace(menu.buf, menu.ns, 0, -1)
  -- TODO api.nvim_buf_add_highlight(menu.buf, menu.ns, 'hl_group', line, col_start, col_end)
end

function M.shift_item(menu, dir)
  local pos = 0
  menu.idx = dir == 0 and
  (menu.idx - 1 >= 1            and menu.idx - 1 or 1) or
  (menu.idx + 1 <= #menu.pItems and menu.idx + 1 or #menu.pItems)
  for i=1, menu.idx do
    pos = pos + #menu.pItems[menu.idx].name + 1
  end
  -- Current implementation is moving the cursor, maybe we can set the highlight
  api.nvim_win_set_cursor(menu.window, {1, pos - 1})
  menu.pItems[menu.idx].callback()
end

function M.enter_item(menu)
  local items = menu.items[menu.idx].next_items
  if (items) then
    menu.pItems = items
    menu.idx = 1
    M.draw_menu(menu)
    do return true end
  else
    do return false end
  end
end

return M
