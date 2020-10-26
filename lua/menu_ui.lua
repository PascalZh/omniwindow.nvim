local M = {}
local api = vim.api

M.LEFT = 0
M.RIGHT = 1
M.highlight = nil -- TODO: create common highlight scheme

function M.create_menu(args, apps)
  local menu = {
    buf = api.nvim_create_buf(false, true),
    win = nil,
    win_opts = {
      relative='editor', style='minimal',
      row=args.row, col=args.col, width=args.width, height=1
    },
    ns = api.nvim_create_namespace('MenuUIHighlights'),

    apps = apps or {
      {
        name = 'foo',
        description = 'just for test',
        cb_enter = function() end,
        cb_leave = function() end,
      }
    },
    app_idx = 1,

    ui = {
      header = ' ',
      left_border = '',  -- #left_border must equal #right_border
      right_border = '',
    },
  }

  api.nvim_buf_set_option(menu.buf, 'modifiable', false)
  return menu
end

function M.is_menu_open(menu)
  return menu.win and vim.fn.bufwinid(menu.buf) == menu.win
end

function M.is_menu_closed(menu)
  return not menu.win or vim.fn.winbufnr(menu.win) ~= menu.buf
end

function M.open_menu(menu)
  if (M.is_menu_open(menu)) then
    do return end
  end
  menu.apps[menu.app_idx].cb_enter()

  menu.win = api.nvim_open_win(menu.buf, false, menu.win_opts)
end

function M.close_menu(menu)
  if (M.is_menu_closed(menu)) then
    do return end
  end
  menu.apps[menu.app_idx].cb_leave()

  api.nvim_win_close(menu.win, false)
  menu.win = nil
end

function M.toggle_menu(menu)
  if (M.is_menu_closed(menu)) then
    M.open_menu(menu)
  elseif (M.is_menu_open(menu)) then
    M.close_menu(menu)
  else
    error("menu is not open and not closed!")
  end
end

--┌─────────────────────────────────────────────────────────────┐
--│                           ui                                │
--└─────────────────────────────────────────────────────────────┘
local function calc_app_col_range(menu)
  -- app is displayed in an array of chars, this app caculate the range of chars
  -- the range will be used to highlight the app
  local pos = #menu.ui.header  -- zero indexed and exclusive
  local apps = menu.apps
  for i = 1, #apps do
    pos = pos + 1
    apps[i].col_start = pos
    pos = pos + #apps[i].name + #menu.ui.left_border + #menu.ui.right_border
    apps[i].col_end = pos
  end
end

local function highlight_cur_app(menu)
  local cur_app = menu.apps[menu.app_idx]
  api.nvim_buf_clear_namespace(menu.buf, menu.ns, 0, -1)
  api.nvim_buf_add_highlight(menu.buf, menu.ns,
    'ErrorMsg', 0, cur_app.col_start, cur_app.col_end)
end

function M.draw_menu(menu)
  calc_app_col_range(menu)

  local lines = { menu.ui.header }   -- menu_ui only has one line
  for idx,val in ipairs(menu.apps) do
    lines[1] = lines[1] .. " " .. menu.ui.left_border .. val.name .. menu.ui.right_border
  end
  api.nvim_buf_set_option(menu.buf, 'modifiable', true)
  api.nvim_buf_set_lines(menu.buf, 0, 1, false, lines)
  api.nvim_buf_set_option(menu.buf, 'modifiable', false)

  highlight_cur_app(menu)
end

function M.shift_item(menu, dir)
  local apps = menu.apps
  local i = menu.app_idx
  local n = #apps
  menu.app_idx = dir == M.LEFT and
  (i - 1 >= 1 and i - 1 or 1) or (i + 1 <= n and i + 1 or n)

  highlight_cur_app(menu)
  apps[i].cb_leave()
  apps[menu.app_idx].cb_enter()
end

return M
