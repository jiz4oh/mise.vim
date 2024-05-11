function! mise_ruby#ruby_version(dir)
  let dir = fnamemodify(a:dir, ':p')
  if !empty($MISE_RUBY_VERSION)
    let ver = $MISE_RUBY_VERSION
  else
    let stdout = system('cd ' . dir .' && mise current ruby')
    if !empty(stdout) && v:shell_error == 0
      let ver = matchstr(stdout, '\v\d+\.\d+\.\d+')
    else
      return
    endif
  endif

  return ver
endfunction
