" mise.vim - mise support
" Maintainer:   jiz4oh <http://jiz4oh.com/>
" Version:      0.1
if !exists('g:ruby_version_paths')
  let g:ruby_version_paths = {}
endif

let s:version_paths_loaded = 0
let s:last_env_dir = ''

function! mise#ruby#version_paths() abort
  let dict = {}
  let root = mise#root() . '/installs/ruby/'
  for entry in glob(root . '*', 0, 1)
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

function! mise#ruby#load_paths() abort
  if s:version_paths_loaded
    return
  endif

  call extend(g:ruby_version_paths, mise#ruby#version_paths(), 'keep')
  let s:version_paths_loaded = 1
endfunction

function! mise#ruby#set_paths(...) abort
  call mise#ruby#load_paths()
  let dir = a:0 ? a:1 : getcwd()
  let ver = mise#ruby#version(dir)
  if has_key(g:ruby_version_paths, ver)
    let g:ruby_default_path = g:ruby_version_paths[ver]
  else
    unlet! g:ruby_default_path
  endif
  return ver
endfunction

function! s:ruby_items(paths, suffix) abort
  return map(copy(a:paths), 'v:val ==# "." ? "" : v:val . a:suffix')
endfunction

function! s:clean_ruby_items(value, suffix) abort
  let drop = {}
  for paths in values(g:ruby_version_paths)
    for item in s:ruby_items(paths, a:suffix)
      if !empty(item)
        let drop[item] = 1
      endif
    endfor
  endfor
  return filter(split(a:value, ','), 'empty(v:val) || !has_key(drop, v:val)')
endfunction

function! mise#ruby#apply_paths(version) abort
  if exists('g:ruby_path') || !has_key(g:ruby_version_paths, a:version)
    return
  endif

  let paths = g:ruby_version_paths[a:version]
  let ruby_path = s:ruby_items(paths, '')
  let old_path = s:clean_ruby_items(&l:path, '')
  let &l:path = join(ruby_path + old_path, ',')

  let ruby_tags = s:ruby_items(paths, '/tags')
  let old_tags = s:clean_ruby_items(&l:tags, '/tags')
  let &l:tags = join(old_tags + ruby_tags, ',')
endfunction

function! mise#ruby#project_dir(dir) abort
  let dir = substitute(fnamemodify(a:dir, ':p'), '/$', '', '')
  let markers = ['.mise.toml', 'mise.toml', '.mise/config.toml', '.config/mise/config.toml', '.ruby-version', '.tool-versions']

  while !empty(dir)
    for marker in markers
      if filereadable(dir . '/' . marker)
        return dir
      endif
    endfor

    let parent = fnamemodify(dir, ':h')
    if parent ==# dir
      break
    endif
    let dir = parent
  endwhile

  return substitute(fnamemodify(a:dir, ':p'), '/$', '', '')
endfunction

function! mise#ruby#activate(...) abort
  let dir = a:0 ? a:1 : expand('%:p:h')
  let apply_paths = a:0 > 1 ? a:2 : 0
  let env_dir = mise#ruby#project_dir(dir)
  if get(g:, 'mise_auto', 1) && env_dir !=# s:last_env_dir
    call mise#env#export(1, env_dir)
    let s:last_env_dir = env_dir
  endif
  let ver = mise#ruby#set_paths(dir)
  if !empty(ver)
    let b:ruby_version = ver
    if apply_paths
      call mise#ruby#apply_paths(ver)
    endif
  endif
endfunction

function! mise#ruby#version(dir)
  let dir = fnamemodify(a:dir, ':p')
  if !empty($MISE_RUBY_VERSION)
    let stdout = $MISE_RUBY_VERSION
  else
    let cmd = 'cd ' . shellescape(dir) . ' && ' . shellescape(get(g:, 'mise_cmd', 'mise')) . ' current ruby'
    let stdout = system(cmd)
    if empty(stdout) || v:shell_error != 0
      return
    endif
  endif

  return matchstr(stdout, '\v\d+\.\d+\.\d+')
endfunction
