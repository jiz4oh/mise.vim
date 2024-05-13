" mise.vim - mise support
" Maintainer:   jiz4oh <http://jiz4oh.com/>
" Version:      0.1
if !exists('g:ruby_version_paths')
  let g:ruby_version_paths = {}
endif

function! mise#ruby#version_paths() abort
  let dict = {}
  let root = mise#root() . '/installs/ruby/'
  for entry in split(glob(root.'*'))
    let ver = entry[strlen(root) : -1]
    let paths = ver =~# '^1.[0-8]' ? ['.'] : []
    let paths += split($RUBYLIB, ':')
    let site_ruby_arch = glob(entry . '/lib/ruby/site_ruby/*.*/*-*')
    if empty(site_ruby_arch) || site_ruby_arch =~# "\n"
      continue
    endif
    let arch = fnamemodify(site_ruby_arch, ':t')
    let minor = fnamemodify(site_ruby_arch, ':h:t')
    let paths += [
          \ entry . '/lib/ruby/site_ruby/' . minor,
          \ entry . '/lib/ruby/site_ruby/' . minor . '/' . arch,
          \ entry . '/lib/ruby/site_ruby',
          \ entry . '/lib/ruby/vendor_ruby/' . minor,
          \ entry . '/lib/ruby/vendor_ruby/' . minor . '/' . arch,
          \ entry . '/lib/ruby/vendor_ruby',
          \ entry . '/lib/ruby/' . minor,
          \ entry . '/lib/ruby/' . minor . '/' . arch]
    let dict[ver] = paths
  endfor
  return dict
endfunction

function! mise#ruby#set_paths() abort
  call extend(g:ruby_version_paths, mise#ruby#version_paths(), 'keep')
  let ver = mise#ruby#version('~')
  if has_key(g:ruby_version_paths, ver)
    let g:ruby_default_path = g:ruby_version_paths[ver]
  else
    unlet! g:ruby_default_path
  endif
endfunction

function! mise#ruby#version(dir)
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
