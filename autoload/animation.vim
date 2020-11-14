if !exists("g:animation_fps")
  let g:animation_fps = 30
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
if !exists("g:animation_task_queue")
  let g:animation_task_queue = 0
endif

let s:interval = 1000 / g:animation_fps
let s:lock = 0
let s:task_queue = []

function s:anim_loop(timer_id, start, end, duration, f, action, t0, state)
  let elapsed = s:time() - a:t0
  let y = float2nr(a:f(a:end - a:start, a:duration, elapsed) + a:start)
  let state_ = a:action(y, a:state)

  if elapsed < a:duration
    call timer_start(s:interval, {id -> s:anim_loop(id, a:start, a:end, a:duration, a:f, a:action, a:t0, state_)})
  else " Ensure a:action(a:end, state) is called
    if y != a:end
      call a:action(a:end, a:state)
    endif

    let s:lock = 0
    if g:animation_task_queue && s:task_queue != []
      let arg = remove(s:task_queue, 0)
      call animation#animate(arg[0], arg[1], arg[2], arg[3], arg[4], arg[5])

      if s:task_queue == []
        let g:animation_task_queue = 0
      endif
    endif
  endif
endfunction

function! animation#animate(start, end, duration, f, action, cmd) abort
  if s:lock == 1 && g:animation_lock
    let s:task_queue += [[a:start, a:end, a:duration, a:f, a:action, a:cmd]]
    return
  endif
  let s:lock = 1

  execute a:cmd
  let start_ = a:start()
  let end_ = a:end()
  let t0 = s:time()
  let state = start_

  call timer_start(s:interval, {id -> s:anim_loop(id, start_, end_, a:duration, a:f, a:action, t0, state)})
endfunction

function! animation#cmd(cmd)
  call animation#animate({->0}, {->0}, 0, {->0}, {->0}, a:cmd)
endfunction

function! s:resize(y, state, vertical)
  let delta = a:y - a:state
  if delta != 0
    if a:vertical
      execute 'vertical resize' . string(a:y)
    else
      execute 'resize' . string(a:y)
    endif
    return a:y
  endif
  return a:state
endfunction

function! animation#vertical_resize_delta(delta)
  call animation#animate({-> winwidth(0)}, {-> winwidth(0) + a:delta},
        \ g:animation_duration, 
        \ function(g:animation_f), {y, state -> s:resize(y, state, 1)}, '')
endfunction

function! animation#resize_delta(delta)
  call animation#animate({-> winheight(0)}, {-> winheight(0) + a:delta},
        \ g:animation_duration, 
        \ function(g:animation_f), {y, state -> s:resize(y, state, 0)}, '')
endfunction

function! s:scroll(y, state, up)
  if a:up
    let action = "\<C-e>"
  else
    let action = "\<C-y>"
  endif

  let delta = a:y - a:state
  if delta >= 1
    execute 'normal! ' . string(delta) . action
    return a:y
  endif
  return a:state
endfunction

function! animation#scroll_up(delta)
  call animation#animate({-> 0}, {-> a:delta}, g:animation_duration,
        \ function(g:animation_f), {y, state -> s:scroll(y, state, 1)}, '')
endfunction

function! animation#scroll_down(delta)
  call animation#animate({-> 0}, {-> a:delta}, g:animation_duration,
        \ function(g:animation_f), {y, state -> s:scroll(y, state, 0)}, '')
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
