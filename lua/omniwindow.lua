local M = {}
local api = vim.api
local menu_ui = require"menu_ui"

M.LEFT=menu_ui.LEFT
M.RIGHT=menu_ui.RIGHT
local function set_shift_item_keymap(buf, mode, key, dir)
  local mapped_code = ':lua require"omniwindow".menu.shift_item('.. dir .. ')<cr>'
  if mode == 't' then
    mapped_code = '<C-\\><C-n>'..mapped_code
  elseif mode == 'i' then
    mapped_code = '<C-[>'..mapped_code
  end
  api.nvim_buf_set_keymap(buf, mode, key, mapped_code, {silent = true})
end

local terminal = {
  name = 'terminal',
  opts = {
    relative='editor', style='minimal',
    row=3, col=10, width=api.nvim_get_option("columns") - 20, height=30
  },
}
function terminal.cb_enter()
  if terminal.buf then
    terminal.win = api.nvim_open_win(terminal.buf, true, terminal.opts)
    vim.fn.execute("normal! i")
  else
    terminal.win = api.nvim_open_win(0, true, terminal.opts)
    vim.fn.execute("terminal")
    terminal.buf = vim.fn.winbufnr(0)
    set_shift_item_keymap(terminal.buf, 't', '<A-h>', M.LEFT)
    set_shift_item_keymap(terminal.buf, 't', '<A-l>', M.RIGHT)
    api.nvim_buf_set_option(terminal.buf, 'buflisted', false)
  end
end
function terminal.cb_leave()
  if terminal.win then
    api.nvim_win_close(terminal.win, false)
  end
end

local foo = {
  name = 'foo',
}
function foo.cb_enter()
  if foo.buf then
    foo.win = api.nvim_open_win(foo.buf, true, terminal.opts)
  else
    foo.buf = api.nvim_create_buf(false, true)
    foo.win = api.nvim_open_win(foo.buf, true, terminal.opts)
    set_shift_item_keymap(foo.buf, 'n', '<A-h>', M.LEFT)
    set_shift_item_keymap(foo.buf, 'n', '<A-l>', M.RIGHT)
  end
end
function foo.cb_leave()
  api.nvim_win_close(foo.win, false)
end

--┌─────────────────────────────────────────────────────────┐
--│                         menu                            │
--└─────────────────────────────────────────────────────────┘
M.menu = menu_ui.create_menu({
  row = 2, col = 10, width = api.nvim_get_option("columns") - 20
}, 
{terminal, foo})

menu_ui.draw_menu(M.menu)

function M.menu.shift_item(dir)
  menu_ui.shift_item(M.menu, dir)
end

function M.menu.toggle()
  menu_ui.toggle_menu(M.menu)
end

function M.menu.focus()
  api.nvim_set_current_win(M.menu.win)
end

return M
