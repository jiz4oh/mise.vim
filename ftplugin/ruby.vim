if get(g:, 'loaded_mise', 0)
  call mise#ruby#activate(expand('%:p:h'), exists('b:did_ftplugin'))
endif
