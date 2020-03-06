let g:translator_split_cmd = "vsplit"

let s:buf_src = -1
let s:buf_ui = -1
let s:win_ui = -1
let s:mark_empty_line = string(localtime())

let s:translated = {}
let s:current_path = expand('<sfile>:p:h')

let s:py_inited = v:false

" function! translator#split(args) {{{
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

    augroup Z_Translator
        au!
        au! InsertEnter <buffer> call <SID>open_translator_win()
        au! InsertLeave <buffer> call <SID>close_translator_win()
    augroup END

endfunction
" }}}

" function! s:open_translator_win() {{{
function! s:open_translator_win()
    call nvim_buf_set_lines(s:buf_ui, 0, 99999, v:false, [''])
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
" }}}

" fun! s:close_translator_win() {{{
fun! s:close_translator_win()
    call nvim_win_close(s:win_ui, v:false)
endf
" }}}

" fun! s:get_current_line_translation() {{{
fun! s:get_current_line_translation()
    let cur_line = line('.') - 1
    let src_line = nvim_buf_get_lines(s:buf_src, cur_line, cur_line+1, v:false)
    if src_line == []
        let content_ = 'No corresponding line in the source file.'
    else
        let idx = substitute(substitute(src_line[0], '^\s*', '', ''), '\s*$', '', '')
        if !has_key(s:translated, idx)
            if idx == ''
                let content_ = ''
            else
                let content_ = translator#translate(idx)[0]
            endif
        else
            let content_ = s:translated[idx]
        endif
    endif
    return content_
endf
" }}}

" fun! translator#put_translation_ln() {{{
fun! translator#put_translation_ln()
    let cur_line = line('.') - 1
    call nvim_buf_set_lines(0, cur_line, cur_line+1, v:false
                \ , [<SID>get_current_line_translation()])
endf
" }}}

" fun! translator#translate(src) {{{
fun! translator#translate(src)
    echo "Translating..."
    if type(a:src) != type('')
        echom "a:src should be a string!"
        return
    elseif len(a:src) > 5000
        echom "a:src is big than 5000 characters, translating may be failing."
    endif
    call <SID>init_py()
    python3 << EOF
src = vim.eval('a:src')
r = translate_safe(src)
EOF
    return <SID>parse_response(py3eval('r'))
endf
" }}}

" fun s:parse_response(r) {{{
fun! s:parse_response(r)
    if type(a:r) != type('') || a:r == ''
        echom "s:parse_response(r): a:r is not string or empty!   a:r=".
                    \ string(a:r)
        return []
    endif
    let r_ = eval(a:r)
    if type(r_) != type({})
        echom "s:parse_response(r): eval(a:r) is not a dict!   eval(a:r)=".
                    \ string(r_).
                    \ "    a:r=".string(a:r)
        return []
    endif
    let ret = []
    if has_key(r_, 'trans_result')
        let ts_ = r_['trans_result']
        for t_ in ts_
            let s:translated[t_['src']] = t_['dst']
            let ret += [t_['dst']]
        endfor
    endif
    return ret
endf
" }}}

" fun! s:init_py() {{{
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
" }}}

" fun! translator#refresh_all_v1() {{{
fun! translator#refresh_all_v1()
    " this variable makes Baidu output the translated list of the same length.
    let s:mark_empty_line = string(localtime())
    let src_ = nvim_buf_get_lines(s:buf_src, 0, 99999, v:false)
    let src__ = []
    for l_ in src_
        if match(l_, '^\s*$') != -1
            let src__ += [l_.s:mark_empty_line]
        else
            let src__ += [l_]
        endif
    endfor
    let src__ = join(src__, "\n")
    call translator#translate(src__)
endf
" }}}

" fun! translator#refresh_all_v2_job() {{{
fun! translator#refresh_all_v2_job()
    " this function has some encode problems
    let s:mark_empty_line = string(localtime())
    let src_ = nvim_buf_get_lines(s:buf_src, 0, 99999, v:false)
    let src__ = []
    for l_ in src_
        if match(l_, '^\s*$') != -1
            let src__ += [l_.s:mark_empty_line]
        else
            let src__ += [l_]
        endif
    endfor

    let s:chunks = ['']
    func! s:on_stdout(job_id, data, event) dict
        let s:chunks[-1] .= a:data[0]
        call <SID>parse_response(s:chunks[-1])
        call extend(s:chunks, a:data[1:])
    endf
    func! s:on_stderr(job_id, data, event) dict
        echom 'stderr: '.string(a:data)
    endf

    let s:job = jobstart(['python3',  s:current_path.'/translator_job.py'], {
                \ 'on_stdout': function('s:on_stdout'),
                \ 'on_stderr': function('s:on_stderr')
                \ })
    call chansend(s:job, src__)
endf
" }}}

" fun translator#stop_translator_job() {{{
fun translator#stop_translator_job()
    call jobstop(s:job)
endf
" }}}
