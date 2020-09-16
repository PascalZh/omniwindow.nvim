" Create commands
if &cp || exists("g:loaded_omniwindow")
    finish
endif
let g:loaded_omniwindow = 1

let g:omniwindow_margin = 3
command! ZOmniwindowToggle lua require"omniwindow".menu.toggle()
command! ZOmniwindowFocusMenu lua require"omniwindow".menu.focus()

command! -nargs=1 -complete=file ZTransSplit
            \ call translator#split('<args>')
command! -nargs=1 ZTransPutLn call translator#put_ln('<args>')
command! ZTransRefreshAll echomsg string(translator#refresh_all_v1())
command! ZTransRefreshAllAsync echomsg string(translator#refresh_all_v2_job())
command! -nargs=1 ZTransTranslate echomsg string(translator#translate('<args>'))
