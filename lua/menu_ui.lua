local M = {}
local api = vim.api

M.LEFT = 0
M.RIGHT = 1

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
      left_border = '',
      right_border = '',
      highlight = { '#3D07E8', '#1FE807' },
    },
  }
  local hi1 = menu.ui.highlight[1]
  local hi2 = menu.ui.highlight[2]
  api.nvim_command('hi OmniwindowMenuUI_1f guifg='..hi1)
  api.nvim_command('hi OmniwindowMenuUI_1b guibg='..hi1)
  api.nvim_command('hi OmniwindowMenuUI_2f guifg='..hi2)
  api.nvim_command('hi OmniwindowMenuUI_2b guibg='..hi2)

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
  local pos = string.len(menu.ui.header)
  -- byte indexed and exclusive since nvim_buf_add_highlight use byte-indexing too.

  local apps = menu.apps
  for i = 1, #apps do
    pos = pos + 1
    apps[i].col_start = pos
    pos = pos + string.len(apps[i].name) + string.len(menu.ui.left_border) +
      string.len(menu.ui.right_border)
    apps[i].col_end = pos
  end
end

local function highlight_cur_app(menu)
  api.nvim_buf_clear_namespace(menu.buf, menu.ns, 0, -1)

  local n_h = string.len(menu.ui.header)
  local n_l = string.len(menu.ui.left_border)
  local n_r = string.len(menu.ui.right_border)
  api.nvim_buf_add_highlight(menu.buf, menu.ns,
    'OmniwindowMenuUI_1f', 0, 0, n_h)

  for i, app in ipairs(menu.apps) do
    local s, e = app.col_start, app.col_end
    local hi_b, hi_f
    if i == menu.app_idx then
      hi_b = 'OmniwindowMenuUI_2b'
      hi_f = 'OmniwindowMenuUI_2f'
    else
      hi_b = 'OmniwindowMenuUI_1b'
      hi_f = 'OmniwindowMenuUI_1f'
    end

    api.nvim_buf_add_highlight(menu.buf, menu.ns,
      hi_f, 0, s, s+n_l)
    api.nvim_buf_add_highlight(menu.buf, menu.ns,
      hi_f, 0, e-n_r, e)
    api.nvim_buf_add_highlight(menu.buf, menu.ns,
      hi_b, 0, s+n_l, e-n_r)
  end
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
