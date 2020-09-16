local M = {}
local api = vim.api

function M.create_menu(args, items)
  local menu = {
    buf = api.nvim_create_buf(false, true),
    opts = {
      relative='editor', style='minimal',
      row=args.row, col=args.col, width=args.width, height=1
    },

    items = items or {
      {
        name = 'foo',
        cb_enter = function() end,
        cb_leave = function() end,

        next_items = nil
      }
    },

    idx = 1,
    pItems = nil,
    ns = api.nvim_create_namespace('MenuUIHighlights')
  }

  menu.pItems = menu.items

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
  local curItem = menu.pItems[menu.idx]
  menu.window = api.nvim_open_win(menu.buf, enter or true, menu.opts)
  api.nvim_win_set_cursor(menu.window,
    {1, curItem.col_end - 1})
  menu.pItems[menu.idx].cb_enter()
end

function M.close_menu(menu)
  if (M.is_menu_closed(menu)) then
    do return end
  end
  api.nvim_win_close(menu.window, false)
  menu.pItems[menu.idx].cb_leave()
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
local function calc_col(menu)
  local pos = 0
  for i = 1, #menu.pItems do
    pos = pos + 1
    menu.pItems[i].col_start = pos  -- zero indexed
    pos = pos + #menu.pItems[i].name
    menu.pItems[i].col_end = pos  -- zero indexed and exclusive
  end
  --for i, k in ipairs(menu.pItems) do
  --  print(tostring(k.col_start) .. ", " .. tostring(k.col_end))
  --end
end

function M.draw_menu(menu)
  if not menu.pItems then
    do return end
  end

  calc_col(menu)

  local lines = { "" }
  for idx,val in ipairs(menu.pItems) do
    lines[1] = lines[1] .. " " .. val.name
  end
  api.nvim_buf_set_option(menu.buf, 'modifiable', true)
  api.nvim_buf_set_lines(menu.buf, 0, 1, false, lines)
  api.nvim_buf_set_option(menu.buf, 'modifiable', false)

  local curItem = menu.pItems[menu.idx]
  api.nvim_buf_clear_namespace(menu.buf, menu.ns, 0, -1)
  api.nvim_buf_add_highlight(menu.buf, menu.ns,
    'TermCursor', 0, curItem.col_start, curItem.col_end)
end

function M.shift_item(menu, dir)
  local old_idx = menu.idx
  menu.idx = dir == 0 and
  (menu.idx - 1 >= 1            and menu.idx - 1 or 1) or
  (menu.idx + 1 <= #menu.pItems and menu.idx + 1 or #menu.pItems)

  local item = menu.pItems[menu.idx]

  api.nvim_win_set_cursor(menu.window, {1, item.col_end - 1})

  api.nvim_buf_clear_namespace(menu.buf, menu.ns, 0, -1)
  api.nvim_buf_add_highlight(menu.buf, menu.ns, 'TermCursor', 0, item.col_start, item.col_end)

  menu.pItems[old_idx].cb_leave()
  menu.pItems[menu.idx].cb_enter()
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
