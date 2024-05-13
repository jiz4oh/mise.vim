" mise.vim - mise support
" Maintainer:   jiz4oh <http://jiz4oh.com/>
" Version:      0.1

if exists('g:loaded_mise') || v:version < 700 || &compatible || !executable('mise')
  finish
endif
let g:loaded_mise = 1
let s:mise_auto = get(g:, 'mise_auto', 1)

command! -nargs=0 -bang MiseExport call mise#env#export(<bang>0)
command! -nargs=0 -bang MiseEdit call mise#edit#miserc(<bang>0)

augroup mise
  au!
  autocmd VimEnter * call mise#ruby#set_paths()

  if s:mise_auto
    autocmd VimEnter * MiseExport

    if exists('##DirChanged')
      autocmd DirChanged * MiseExport!
    else
      autocmd BufEnter * MiseExport
    endif
  endif
augroup END
" vim:set et sw=2:
