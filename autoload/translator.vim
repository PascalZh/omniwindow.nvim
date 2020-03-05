let g:translator_split_cmd = "vsplit"
let s:buf_src = -1
let s:buf_ui = -1
let s:win_ui = -1
let s:translated = []
let s:current_path = expand('<sfile>:p:h')
"call nvim_buf_clear_namespace(0, s:ns, 0, -1)

function! translator#split(args)
    if a:args == '--help'
        echo ":ZTranslatorSplit src dst or open src first and run :ZTranslatorSplit dst"
        return
    endif
    if len(split(a:args)) > 2
        echom "Too many arguments are given, require 1 or 2 arguments."
        return
    endif
    let s:buf_ui = nvim_create_buf(v:false, v:true)

    let args_ = split(a:args)

    func Setup_source_buffer()
        let s:buf_src = nvim_get_current_buf()
        if &fenc != 'utf-8'
            echom "file encoding is not utf-8! exiting..."
            return -1
        endif
        setlocal scrollbind|setlocal cursorbind
        setlocal cursorline|setlocal cursorcolumn
        return 0
    endfunc
        
    if len(args_) == 1
        if Setup_source_buffer() == -1
            return
        endif
        exe g:translator_split_cmd." ".args_[0]
    elseif len(args_) == 2
        exe "edit ".args_[0]
        if Setup_source_buffer() == -1
            return
        endif
        exe g:translator_split_cmd." ".args_[1]
    endif

    setlocal scrollbind|setlocal cursorbind
    setlocal cursorline

    " translate the content
    let l:src = nvim_buf_get_lines(s:buf_src, 0, 99999, v:false)
    python3 << EOF
import vim; import sys; sys.path.append(vim.eval('s:current_path'))
from translator_api import translate, escacpe_vim
src_lst = vim.eval('l:src')
json_ = translate("\n".join(src_lst))
dst_lst = []
if 'trans_result' not in json_.keys():
    print("fail to translate!")
else:
    dst = [ t['dst'] for t in json_['trans_result']]
    j = 0
    for i, l in enumerate(src_lst):
        # "FIXME
        # "align dst_lst to src_lst, because len(dst) may be not equal to
        # "len(src_lst). The following condition works well now, but maybe
        # "need to update in other case
        if l.isspace() or l == '':
            dst_lst.append('')
        else:
            if j < len(dst):
                dst_lst.append(escacpe_vim(dst[j]))
            else:
                dst_lst.append('source file and destination file line number not equal')
            j = j + 1
vim.command("let s:translated=" + dst_lst.__repr__())
EOF

    augroup Z_Translator
        au!
        au! InsertEnter <buffer> call <SID>open_translator_win()
        au! InsertLeave <buffer> call <SID>close_translator_win()
    augroup END

    echom "In order to exchange data between python3 and vimL, ' and \" are replaced with `, \\ are all deleted from the translated text."
endfunction

function s:open_translator_win()
    let cur_line = line('.') - 1
    let pos_ = winline()
    let width_ = nvim_win_get_width(0)
    if cur_line < len(s:translated)
        let dst_ = s:translated[cur_line]
        let height_ = 1 + float2nr(len(dst_) / nvim_win_get_width(0) + 0.5)
        let s:opts = {'relative': 'win'
                    \ , 'width': width_
                    \ , 'height': height_
                    \ , 'col': 0, 'row': pos_ + 2
                    \ , 'anchor': 'NW', 'style': 'minimal'}
        let s:win_ui = nvim_open_win(s:buf_ui, v:false, s:opts)
        call nvim_buf_set_lines(s:buf_ui, 0, 99999, v:false
                    \ , [dst_])
    else
        let height_ = 3
        let s:opts = {'relative': 'win'
                    \ , 'width': width_
                    \ , 'height': height_
                    \ , 'col': 0, 'row': pos_ + 2
                    \ , 'anchor': 'NW', 'style': 'minimal'}
        let s:win_ui = nvim_open_win(s:buf_ui, v:false, s:opts)
        call nvim_buf_set_lines(s:buf_ui, 0, 99999, v:false
                    \ , ["Line index out of range, no translated lines are available."])
    endif
endfunction

fun s:close_translator_win()
    call nvim_win_close(s:win_ui, v:false)
endf
