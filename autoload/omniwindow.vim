" fun omniwindow#foo() {{{1
fun! omniwindow#foo()
    lua menu = require "menu"
    lua print(menu.foo())
endf

