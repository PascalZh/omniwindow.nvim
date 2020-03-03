if !exists("g:easy_jk_timeout")
    let g:easy_jk_timeout = 100
endif

let s:j_pressed = v:false
let s:k_pressed = v:false

func! easy_jk#map_j()
    let s:j_pressed = v:true
    call timer_start(g:easy_jk_timeout, function("<SID>reset_j_pressed"))
    if s:k_pressed == v:true
        call blitz#on_input_exit()
        return "\<Backspace>\<Esc>"
    endif
    return "j"
endfunc

func! easy_jk#map_k()
    let s:k_pressed = v:true
    call timer_start(g:easy_jk_timeout, function("<SID>reset_k_pressed"))
    if s:j_pressed == v:true
        call blitz#on_input_exit()
        return "\<Backspace>\<Esc>"
    endif
    return "k"
endfunc

func! s:reset_j_pressed(id)
    let s:j_pressed = v:false
endfunc
func! s:reset_k_pressed(id)
    let s:k_pressed = v:false
endfunc
