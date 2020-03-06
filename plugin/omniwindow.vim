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
command! ZTranslatorPutTranslationLn call translator#put_translation_ln()
command! ZTranslatorRefreshAll echomsg string(translator#refresh_all_v1())
command! ZTranslatorRefreshAllAsync echomsg string(translator#refresh_all_v2_job())
command! -nargs=1 ZTranslatorTranslate echomsg string(translator#translate('<args>'))
