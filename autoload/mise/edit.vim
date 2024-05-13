" mise.vim - mise support
" Maintainer:   jiz4oh <http://jiz4oh.com/>
" Version:      0.1

let s:mise_edit_mode = get(g:, 'mise_edit_mode', 'edit')

let s:default_config_filename = '.mise.toml'

function! s:edit_local() abort
  if $MISE_DEFAULT_CONFIG_FILENAME ==# ''
    let filename = s:default_config_filename
  else
    let filename = $MISE_DEFAULT_CONFIG_FILENAME
  endif

  let filename = s:default_config_filename

  if filename ==# '.mise.toml'
    " https://mise.jdx.dev/profiles.html
    " Note that currently modifying MISE_DEFAULT_CONFIG_FILENAME to something other than .mise.toml will not work with this feature. For now, it will disable it entirely. This may change in the future.
    let files =  [
          \'.mise.local.toml',
          \'.mise/config.local.toml',
          \'.config/mise/config.local.toml',
          \'.mise.toml'
          \'.mise/config.toml'
          \'.config/mise/config.toml',
          \]

    let miserc = ''
    for file in files
      if filereadable(file)
        let miserc = file
        break
      end
    endfor

    if empty(miserc)
      echom 'new miserc file will be created:' . miserc
      let miserc = files[0]
    end

    call mise#edit#execute(miserc)
    return 1
  else
    echom 'Do not support profiles if $MISE_DEFAULT_CONFIG_FILENAME is something other than .mise.toml '
    return 0
  endif
endfunction

function! s:edit_global() abort
  if $MISE_GLOBAL_CONFIG_FILE ==# ''
    if $MISE_CONFIG_DIR !=# ''
      let miserc_dir = $MISE_CONFIG_DIR
    elseif $XDG_CONFIG_HOME !=# ''
      let miserc_dir = $XDG_CONFIG_HOME . '/mise'
    else
      let miserc_dir = $HOME . '/.config/mise'
    endif
    let filename = miserc_dir . '/config.toml'
  else
    let filename = $MISE_GLOBAL_CONFIG_FILE
  end

  if !filereadable(filename)
    echom 'new miserc file will be created:' . filename
  end

  call mise#edit#execute(filename)
endfunction

function! mise#edit#miserc(global) abort
  if a:global || !s:edit_local()
    call s:edit_global()
  endif
endfunction

function! mise#edit#mkdir(dir) abort
  if !exists('*mkdir')
    return 0
  endif
  let l:result = mkdir(a:dir, 'p', 0700)
  return l:result
endfunction

function! mise#edit#execute(file) abort
  execute ':' . s:mise_edit_mode a:file
endfunction
