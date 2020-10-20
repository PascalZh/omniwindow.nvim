# Troubleshooting
* `<C-O>` in insert mode will trigger `InsertLeave`.

* `blitz.vim` and `easy_jk.vim` are coupled, blitz need to close window with jk
mapping when exiting insert mode.

# TODO
- [x] fix the bugs that `easy_jk` module will leave trailing spaces when escape
insert mode from a indented blank line.
- [ ] implement `note.lua`
- [ ] implement `fancy_q`

## `note.vim`
### Outline
A note is a paragraph with its title.

A note's title must be loaded in the memory, so it can be searched.

A note's content can be loaded in the memory later.

All notes are saved into one or several files.

`note.vim` also provide a window as the interface to lookup, add, delete, modify
notes.
