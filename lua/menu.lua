local function create_menu(items)
    local menu = {
        buf = vim.api.nvim_create_buf(false, true),
        opts = { relative='win', style='minimal', row=3, col=3, width=20, height=3 },
        items = items or {
            {
                name = 'foo',
                callback = function() end

                next_items = {
                    {
                        name = 'foobar',
                        callback = function() end
                    }
                },
            },
            {
                name = 'bar',
                callback = function() return "foobar" end

                next_items = nil,
            },
        }
        pItems = items,
        itemIdx = 1
    }

    return menu
end

local function is_menu_open(menu)
    return menu.window and vim.api.bufwinid(menu.buf) == menu.window
end

local function is_menu_closed(menu)
    return not menu.window or vim.api.winbufnr(menu.window) != menu.buf
end

local function open_menu(menu, enter)
    if (is_menu_open(menu)) then
        do return end
    end
    menu.window = vim.api.nvim_open_win(menu.buf, enter, menu.opts)
end

local function close_menu(menu)
    if (is_menu_closed(menu)) then
        do return end
    end
    vim.api.nvim_win_close(menu.window, false)
    menu.window = nil
end

local function toggle_menu(menu)
    if (is_menu_closed(menu)) then
        open_menu(menu)
    elseif (is_menu_open(menu)) then
        close_menu(menu)
    else
        error("menu is not open and closed")
    end
end

--┌─────────────────────────────────────────────────────────────┐
--│                      drawing the ui                         │
--└─────────────────────────────────────────────────────────────┘
local function draw_menu(menu)
    -- TODO
end

local function shift_item(menu)
    -- TODO
end

local function enter_item(menu)
    -- TODO
end

return {
}
