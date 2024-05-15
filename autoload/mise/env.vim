" mise.vim - mise support
" Maintainer:   jiz4oh <http://jiz4oh.com/>
" Version:      0.1

scriptencoding utf-8

let s:mise_cmd = get(g:, 'mise_cmd', 'mise')
let s:mise_interval = get(g:, 'mise_interval', 500)
let s:mise_max_wait = get(g:, 'mise_max_wait', 5)
let s:job_status = { 'running': 0, 'stdout': [], 'stderr': [] }

if !exists('g:mise_silent_load')
  let g:mise_silent_load = 0
endif

function! mise#env#post_mise_load() abort
  doautocmd User MiseLoaded
endfunction

function! mise#env#on_stdout(_, data, ...) abort
  if a:data != ['']
    call extend(s:job_status.stdout, a:data)
  end
endfunction

function! mise#env#on_stderr(_, data, ...) abort
  if a:data != ['']
    call extend(s:job_status.stderr, a:data)
  end
endfunction

function! mise#env#on_exit(_, status, ...) abort
  let s:job_status.running = 0

  call s:process_err(s:job_status.stderr)
  call s:load_env(s:job_status.stdout)
endfunction

function! mise#env#job_status_reset() abort
  let s:job_status['stdout'] = []
  let s:job_status['stderr'] = []
endfunction

function! mise#env#err_cb(_, data) abort
  call mise#env#on_stderr(0, split(a:data, "\n", 1))
endfunction

function! mise#env#out_cb(_, data) abort
  call mise#env#on_stdout(0, split(a:data, "\n", 1))
endfunction

function! mise#env#exit_cb(_, status) abort
  call mise#env#on_exit(0, a:status)
endfunction

if has('nvim')
  let s:job =
        \ {
        \   'on_stdout': 'mise#env#on_stdout',
        \   'on_stderr': 'mise#env#on_stderr',
        \   'on_exit': 'mise#env#on_exit'
        \ }
else
  let s:job =
        \ {
        \   'out_cb': 'mise#env#out_cb',
        \   'err_cb': 'mise#env#err_cb',
        \   'exit_cb': 'mise#env#exit_cb'
        \ }
endif

function! mise#env#export(sync) abort
  call s:export_debounced.do(a:sync)
endfunction

function! mise#env#export_core(sync) abort
  if !executable(s:mise_cmd)
    echom 'No mise executable, add it to your PATH or set correct g:mise_cmd'
    return
  endif

  let l:cmd = [s:mise_cmd, 'env', '--quiet']
  if !a:sync
    if has('nvim')
      call jobstart(l:cmd, s:job)
      return
    elseif has('job') && has('channel')
      if !has('timers')
        if s:job_status.running
          return
        endif
        let s:job_status.running = 1
      endif
      call mise#env#job_status_reset()
      call job_start(l:cmd, s:job)
      return
    endif
  endif

  let lines = system(join(l:cmd))
  if v:shell_error == 0
    call s:load_env(lines)
  else
    call s:process_err(lines)
  end
endfunction

function! s:process_err(lines)
  if !g:mise_silent_load
    for l:m in a:lines
      if l:m isnot# ''
        echom l:m
      endif
    endfor
  endif
endfunction

function! s:load_env(lines)
  for l in a:lines
    let line = substitute(l, '^export \(.*\)=["'']\{,1}\(.\{-}\)["'']\{,1}$', 'let $\1="\2"', '')
    execute line
  endfor
  call mise#env#post_mise_load()
endfunction

let s:export_debounced = {'id': 0, 'counter': 0}

function! s:export_debounced.call(...)
  let self.id = 0
  let self.counter = 0
  call mise#env#export_core(0)
endfunction

function! s:export_debounced.do(sync)
  if has('timers') && !a:sync
    call timer_stop(self.id)
    if self.counter < s:mise_max_wait
      let self.counter = self.counter + 1
      let self.id = timer_start(s:mise_interval, self.call)
    else
      call self.call()
    endif
  else
    call mise#env#export_core(a:sync)
  endif
endfunction
