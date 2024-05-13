" mise.vim - mise support
" Maintainer:   jiz4oh <http://jiz4oh.com/>
" Version:      0.1

function! mise#root()
  return !empty($MISE_DATA_DIR) ? $MISE_DATA_DIR : !empty($XDG_DATA_HOME) ? expand($XDG_DATA_HOME . '/mise') : expand('~/.local/share/mise')
endfunction
