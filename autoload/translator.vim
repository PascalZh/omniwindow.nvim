"call nvim_buf_set_lines(s:buf, 0, 1, v:false, [pinyin])
"call line(".")
" TODO rewrite all codes please!
let s:n_from = 0
let s:n_to = 0
let s:current_line = 0
let s:lst_from = []

function! translator#edit(filelist)
    let l:f = split(a:filelist, " ")
    let l:from = l:f[0]
    let l:to = l:f[1]

    let s:lst_from = readfile(l:from)
    let s:n_from = len(s:lst_from)
    
    exe "edit ".l:to
    let s:n_to = line('$')
    
    let l:empty = ""
    normal! gg
    for i in range(s:n_from)
        if i >= s:n_to
            put =l:empty
        endif
        put! =s:lst_from[i]
        normal! 2j
        
        exe "sleep ".string(1+float2nr(100 * sqrt((s:n_from - i) * 1.0 /(s:n_from))))."m"
        redraw
    endfor
    normal! ggj

    nnoremap <buffer> j 2j
    nnoremap <buffer> k :call <SID>smart_k() \| echo<cr>
    augroup Z_Translator
        au!
        au! InsertEnter <buffer> call <SID>check_even_line()
        au! BufWritePre <buffer> call <SID>save_file()
        au! BufWritePost <buffer> call <SID>save_file_post()
    augroup END
endfunction

function! s:check_even_line()
    if line('.') % 2 == 1
        echoerr "Lines that are to be translated can be edited, but you can't save the change!"
    endif
endfunction

function! s:save_file()
    let s:current_line = line('.')
    normal! gg
    for i in range(s:n_from)
        normal! "_dd
        normal! j
    endfor
endfunction

function! s:save_file_post()
    let l:empty = ""
    normal! gg
    for i in range(s:n_from)
        if i >= s:n_to
            put =l:empty
        endif
        put! =s:lst_from[i]
        normal! 2j
    endfor
    exe "normal! ".string(s:current_line)."G"
endfunction

function! s:smart_k()
    if line('.') != 2
        normal! 2k
    endif
endfunction
