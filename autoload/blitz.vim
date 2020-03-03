let s:blitz_enable = v:false
let s:win = 0
let s:buf = nvim_create_buf(v:false, v:true)
let s:valid_chars = "abcdefghijklmnopqrstuvwxyz"

let s:w = 40
let s:h = 2
let s:col = 1
let s:row = 1
let s:opts = {'relative': 'cursor', 'width': s:w, 'height': s:h, 'col': s:col, 'row': s:row, 'anchor': 'NW', 'style': 'minimal'}

"let s:ns = nvim_create_namespace('blitz')
"call nvim_buf_clear_namespace(0, s:ns, 0, -1)
"call nvim_buf_set_virtual_text(0, s:ns, v:lnum+1, [["EJIwef", "ErrorMsg"]], [])
function! blitz#input_method_open()
    python3 << EOF
import vim
import sys

sys.path.append('.')
import blitz
EOF
    augroup blitz
        au!
        au! TextChangedI <buffer> call <SID>popup_candidate()
        au! InsertCharPre <buffer> call <SID>record_input()
    augroup END
    let s:blitz_enable = v:true
endfunction

function! blitz#input_method_close()
    au! blitz
    let s:blitz_enable = v:false
    call blitz#on_input_exit()
endfunction

function! s:record_input()
    if !exists("b:input_buf")
        let b:input_buf = []
    endif
    if match(s:valid_chars, v:char) != -1
        let b:input_buf += [v:char]
    endif
endfunction

function! s:popup_candidate()
    if !exists("b:input_buf") || b:input_buf == []
        return
    endif
    if s:win == 0 || winbufnr(s:win) == -1
        let s:win = nvim_open_win(s:buf, v:false, s:opts)
        let b:coc_suggest_disable = 1
        inoremap <buffer><expr> <space>
                    \ repeat("\<backspace>", len(b:input_buf)).b:selected
                    \ ."<C-O>:call blitz#on_input_exit() \\| echo<cr>"
        inoremap <buffer> <backspace> <C-O>:call <SID>backspace()<cr><backspace>
    else
        let l:cursor = getcurpos()
        let s:opts.col = l:cursor[3]
        call nvim_win_set_config(s:win, s:opts)
    endif
    call <SID>update_buffer()
endfunction

function! s:backspace()
    if len(b:input_buf) <= 1
        call blitz#on_input_exit()
    else
        let b:input_buf = b:input_buf[:-2]
    endif
endfunction

function! blitz#on_input_exit()
    let b:input_buf = []
    let b:coc_suggest_disable = 0
    if s:win == 0 || winbufnr(s:win) == -1
        return
    endif
    call nvim_win_close(s:win, v:false)
    let s:win = 0
    iunmap <buffer> <space>
    iunmap <buffer> <backspace>
endfunction

function! s:update_buffer()
    let pinyin = join(b:input_buf, "")
    call nvim_buf_set_lines(s:buf, 0, 1, v:false, [pinyin])
    exe "py3 pinyin = "."\"".pinyin."\""

    python3 << EOF
wq = blitz.WordQuery()
# f = open("foo.log", "a")

wq.query(pinyin, 10)
_, words = wq.get_last_query()
vim.command("let words = " + "\"" + "".join(words) + "\"")
# f.close()
EOF
    if len(words) == 0
        let b:selected = pinyin
    else
        let b:selected = strcharpart(words, 0, 1)
    endif
    let candidate_ui = words
    call nvim_buf_set_lines(s:buf, 1, 2, v:false, [candidate_ui])
endfunction
