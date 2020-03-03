" CheatsheetToggle
let s:buf = 0
let s:win = 0
let s:max_lines = 9999
let s:cheatsheet_path = '~/.vim/cheatsheet.txt'
let s:menu = ["☞ Press ? for help"
            \,"  ▶ cheatsheet ▷ mapping"]
" I use s:content to manage content of menu items, and it is similar to buffer
let s:content = {}
let s:buffer_inited = v:false

if !exists('g:omniwindow_sync_path')
    let g:omniwindow_sync_path = '~/Share/omniwindow'
endif

function! omniwindow#toggle(w, h, col, row)
    if s:buf == 0
        let s:buf = nvim_create_buf(v:false, v:true)
    endif
    if s:win == 0 || winbufnr(s:win) == -1
        let s:opts = {'relative': 'win', 'width': a:w, 'height': a:h, 'col': a:col, 'row': a:row, 'anchor': 'NW', 'style': 'minimal'}
        let s:win = nvim_open_win(s:buf, v:true, s:opts)
        if !s:buffer_inited
            call s:init_buffer()
        endif
    else
        call nvim_win_close(s:win, v:false)
        let s:win = 0
    endif
endfunction

function! s:init_buffer()
    syntax match CheatsheetItem /▶ \<\w*\>/hs=s+2
    hi link CheatsheetItem airline_tabmod
    call nvim_buf_set_lines(0, 0, 2, v:false, s:menu)
    normal jeeb
    nnoremap <buffer> <C-S> :call <SID>sync_save()<cr>
    inoremap <buffer> <C-S> <C-O>:call <SID>sync_save()<cr>
    nnoremap <buffer><expr> i
                \ getline(".")[0:2] == '☞' ? <SID>warn_inserting('forbidden') :
                \ "i"
    nnoremap <buffer><expr> h
                \ line(".") == 2 ? <SID>item_move('h') :
                \ "h"
    nnoremap <buffer><expr> l
                \ line(".") == 2 ? <SID>item_move('l') :
                \ "l"
    
    if !exists("s:content.cheatsheet")
        let s:content.cheatsheet = readfile(expand(s:cheatsheet_path))
    endif
    if !exists("s:content.mapping")
        let s:content.mapping = split(system('cat ~/.vim/.vimrc.mapping | ~/.vim/pretty_vimrc_mapping.hs'), "\n")
    endif
    let s:buffer_inited = v:true
endfunction

function! s:item_move(dir)
    let cmd = ":let z_=@z\n".
                \ "\"zyiw".
                \ ":call omniwindow#read_content(@z)\n"
                \ ":let @z=z_\n"
    "echom cmd
    if a:dir == 'h'
        return '0f▶ebF▷r▶f▶r▷F▶eb'.cmd
    endif
    if a:dir == 'l'
        return '0f▶ebf▷r▶F▶r▷f▶eb'.cmd
    endif
endfunction

function! omniwindow#read_content(item)
    " if this occur in map, it cause terminating without warning
    call deletebufline(bufname(), 3, s:max_lines)
    exe "call nvim_buf_set_lines(0, 3, s:max_lines, v:false, s:content.".a:item.")"
endfunction

function! s:warn_inserting(level)
    if a:level == 'forbidden'
        echoerr "The current line is not allowed to modify!"
    endif
endfunction

function! s:sync_save()
    exe 'write '.s:cheatsheet_path
    " execute the sync script
    exe '!~/.vim/bundle/omniwindow.nvim/sync.fish '
                \ .s:cheatsheet_path.' '.g:omniwindow_sync_path
                \ .'>>~/.vim/bundle/omniwindow.nvim/runtime.log 2>&1'
endfunction
