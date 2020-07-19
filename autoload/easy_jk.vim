if !exists("g:easy_jk_timeout")
    let g:easy_jk_timeout = 100
endif

let s:j_pressed = v:false
let s:k_pressed = v:false
let s:esc = "\<Plug>(PearTreeFinishExpansion)"

func! easy_jk#map_j()
    let s:j_pressed = v:true
    call timer_start(g:easy_jk_timeout, function("<SID>reset_j_pressed"))
    if s:k_pressed == v:true
        call s:work_with_other_plugin()

        let current_line = getline('.')
        if match(current_line, '^\s\+k$') == 0
            return "\<Backspace>\<C-w>".s:esc
        else
            return "\<Backspace>".s:esc
        endif
    endif
    return "j"
endfunc

func! easy_jk#map_k()
    let s:k_pressed = v:true
    call timer_start(g:easy_jk_timeout, function("<SID>reset_k_pressed"))
    if s:j_pressed == v:true
        call s:work_with_other_plugin()
   
        let current_line = getline('.')
        if match(current_line, '^\s\+j$') == 0
            return "\<Backspace>\<C-w>".s:esc
        else
            return "\<Backspace>".s:esc
        endif
    endif
    return "k"
endfunc

func! s:reset_j_pressed(id)
    let s:j_pressed = v:false
endfunc
func! s:reset_k_pressed(id)
    let s:k_pressed = v:false
endfunc

func! s:work_with_other_plugin()
    call blitz#on_input_exit()
endfunc
