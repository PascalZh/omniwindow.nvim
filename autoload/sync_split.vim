function! sync_split#split_cmd(cmd)
    " eg. cmd = 'split foo.txt'
    " eg. cmd = 'vsplit foo.txt'
    setlocal scrollbind
    setlocal cursorbind
    
    setlocal cursorcolumn
    setlocal cursorline
    
    exe a:cmd
    
    setlocal scrollbind
    setlocal cursorbind
    
    setlocal cursorline
endfunction
