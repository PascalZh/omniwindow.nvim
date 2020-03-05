let g:translator_split_cmd = "vsplit"

let s:buf_src = -1
let s:buf_ui = -1
let s:win_ui = -1
let s:mark_empty_line = string(localtime())

let s:translated = {}
let s:current_path = expand('<sfile>:p:h')

let s:py_inited = v:false

function! translator#split(args)
    if a:args == '--help'
        echo "run :ZTranslatorSplit src dst or open src first and run :ZTranslatorSplit dst"
        return
    endif
    if len(split(a:args)) > 2
        echom "Too many arguments are given, require 1 or 2 arguments."
        return
    endif
    let s:buf_ui = nvim_create_buf(v:false, v:true)

    let args_ = split(a:args)

    func! s:setup_source_buffer()
        let s:buf_src = nvim_get_current_buf()
        setlocal scrollbind|setlocal cursorbind
        setlocal cursorline
    endfunc

    if len(args_) == 1
        call <SID>setup_source_buffer()
        exe g:translator_split_cmd." ".args_[0]
    elseif len(args_) == 2
        exe "edit ".args_[0]
        call <SID>setup_source_buffer()
        exe g:translator_split_cmd." ".args_[1]
    endif

    setlocal scrollbind|setlocal cursorbind
    setlocal cursorline

    call translator#refresh_all()
    augroup Z_Translator
        au!
        au! InsertEnter <buffer> call <SID>open_translator_win()
        au! InsertLeave <buffer> call <SID>close_translator_win()
    augroup END

    echom "In order to exchange data between python3 and vimL, ' and \" are replaced with `, \\ are all deleted from the translated text."
endfunction

function! s:open_translator_win()
    let pos_ = winline()
    let width_ = nvim_win_get_width(0)

    let content_ = <SID>get_current_line_translation()
    let height_ = 1 + float2nr(len(content_) / nvim_win_get_width(0) + 0.5)
    let s:opts = {'relative': 'win'
                \ , 'width': width_
                \ , 'height': height_
                \ , 'col': 0, 'row': pos_ + 1
                \ , 'anchor': 'NW', 'style': 'minimal'}
    let s:win_ui = nvim_open_win(s:buf_ui, v:false, s:opts)
    call nvim_buf_set_lines(s:buf_ui, 0, 99999, v:false, [content_])
endfunction


fun! s:close_translator_win()
    call nvim_win_close(s:win_ui, v:false)
endf

fun! s:get_current_line_translation()
    let cur_line = line('.') - 1
    let src_line = nvim_buf_get_lines(s:buf_src, cur_line, cur_line+1, v:false)
    if src_line == []
        let content_ = 'No corresponding line in the source file.'
    else
        if !has_key(s:translated, src_line[0])
            if has_key(s:translated, src_line[0].s:mark_empty_line)
                let content_ = ''
            else
                let content_ = 'Loading...'
            endif
        else
            let content_ = s:translated[src_line[0]]
        endif
    endif
    return content_
endf

fun! translator#put_translation_ln()
    let cur_line = line('.') - 1
    call nvim_buf_set_lines(0, cur_line, cur_line+1, v:false
                \ , [<SID>get_current_line_translation()])
endf

fun! translator#translate(src)
    echo "Translating..."
    if type(a:src) != type('')
        echoerr "a:src should be a string!"
        return
    endif
    call <SID>init_py()
    python3 src = vim.eval('a:src')
    python3 r = translate_safe(src)
    return py3eval('r')
endf

fun! s:init_py()
    if !s:py_inited
        python3 << EOF
import vim
import sys
current_path = vim.eval('s:current_path')
if current_path not in sys.path:
    sys.path.append(current_path)
from translator_api import *
EOF
        let s:py_inited = v:true
    else
        return
    endif
endf

fun! translator#refresh_all()
    unlet s:translated
    let s:translated = {}
    " this variable makes Baidu output the translated list of the same length.
    let s:mark_empty_line = string(localtime())
    let src_ = nvim_buf_get_lines(s:buf_src, 0, 99999, v:false)
    let src__ = []
    for l_ in src_
        if match(l_, '\p') == -1
            let src__ += [l_.s:mark_empty_line]
        else
            let src__ += [l_]
        endif
    endfor
    let dst_ = translator#translate(join(src__, "\n"))
    let i = 0
    for l__ in src__
        if match(l__, s:mark_empty_line) != -1
            let s:translated[l__] = ''
            let dst_[i] = ''
        else
            let s:translated[l__] = dst_[i]
        endif
        let i += 1
    endfor
    return dst_
endf
