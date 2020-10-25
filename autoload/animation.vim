if !exists("g:animation_fps")
  let g:animation_fps = 60
endif
if !exists("g:animation_f")
  let g:animation_f = "animation#f_sine"
endif
if !exists("g:animation_duration")
  let g:animation_duration = 300
endif
if !exists("g:animation_lock")
  let g:animation_lock = 1
endif

let s:interval = 1000 / g:animation_fps
let s:lock = 0

function! animation#animate_with_f(start, end, duration, f, func, then) abort
  call assert_true(type(a:start) == type(0) && type(a:end) == type(0))
  if s:lock == 1 && g:animation_lock
    return
  endif
  let s:lock = 1

  let t0 = s:time()
  let y_ = (a:end - a:start)
  let state = 0

  function! s:animate(timer_id) closure
    let elapsed = s:time() - t0
    let number = float2nr(a:f(y_, a:duration, elapsed) + a:start)
    let state = a:func(number, state)
    if elapsed < a:duration
      call timer_start(s:interval, function("s:animate"))
    else
      " Ensure a:func(a:end, state) is called
      if number != a:end
        let state = a:func(a:end, state)
      endif
      call a:then()
      let s:lock = 0
    endif
  endfunction

  call timer_start(s:interval, function("s:animate"))
endfunction

function! s:vertical_resize(number, state)
  execute 'vertical resize' . string(a:number)
endfunction

function! animation#vertical_resize_delta(delta)
  call animation#animate_with_f(winwidth(0), winwidth(0) + a:delta,
        \ g:animation_duration, 
        \ function(g:animation_f), function("s:vertical_resize"), {-> 0})
endfunction

function! s:resize(number, state)
  execute 'resize' . string(a:number)
endfunction

function! animation#resize_delta(delta)
  call animation#animate_with_f(winwidth(0), winwidth(0) + a:delta,
        \ g:animation_duration, 
        \ function(g:animation_f), function("s:resize"), {-> 0})
endfunction

let s:scroll_command_count = 0
function! s:scroll_up(number, state)
  let delta = a:number - a:state
  if delta >= 1
    execute 'normal! ' . string(delta) . "\<C-e>"
    return a:state + delta
  endif
  return a:state
endfunction

function! animation#scroll_up(delta)
  call animation#animate_with_f(0, a:delta, g:animation_duration,
        \ function(g:animation_f), function("s:scroll_up"), {-> 0})
endfunction

function! s:scroll_down(number, state)
  let delta = a:number - a:state
  if delta >= 1
    execute 'normal! ' . string(delta) . "\<C-y>"
    return a:state + delta
  endif
  return a:state
endfunction

function! animation#scroll_down(delta)
  call animation#animate_with_f(0, a:delta, g:animation_duration,
        \ function(g:animation_f), function("s:scroll_down"), {-> 0})
endfunction

" f {{{
function! animation#f_linear(y_, t_, t)
  return 1.0 * a:y_ * (a:t / a:t_)
endfunction

function! animation#f_quad(y_, t_, t)
  let u = a:t / a:t_
  return - 1.0 * a:y_ * u * (u - 2)
endfunction

function! animation#f_cubic(y_, t_, t)
  let v = a:t / a:t_ - 1
  return 1.0 * a:y_ * (v * v * v + 1)
endfunction

function! animation#f_sine(y_, t_, t)
  let u = a:t / a:t_
  let pi = 3.14159265359
  return a:y_ * 0.5 * (1 - cos(pi * u))
endfunction
" }}}

function! s:time()
  return reltimefloat(reltime()) * 1000.0
endfunction
