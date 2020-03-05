" Create commands
if &cp || exists("g:loaded_omniwindow")
    finish
endif
let g:loaded_omniwindow = 1

let g:omniwindow_margin = 3
command! ZOmniwindowToggle :call omniwindow#toggle(
            \ winwidth(0) - 4 * g:omniwindow_margin,
            \ winheight(0) - 2 * g:omniwindow_margin,
            \ 2 * g:omniwindow_margin,
            \ g:omniwindow_margin)

command! -nargs=1 -complete=file ZTranslatorSplit
            \ call translator#split('<args>')
