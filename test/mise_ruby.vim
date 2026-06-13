set nocompatible
set nomore

let s:repo = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let s:tmp = tempname()
let s:home = s:tmp . '/home'
let s:project = s:tmp . '/project'
let s:mise_data = s:tmp . '/mise'
let s:bin = s:tmp . '/bin'
let s:mise_log = s:tmp . '/mise.log'

function! s:InstallRuby(version, minor) abort
  let root = s:mise_data . '/installs/ruby/' . a:version . '/lib/ruby'
  call mkdir(root . '/site_ruby/' . a:minor . '/x86_64-darwin', 'p')
  call mkdir(root . '/vendor_ruby/' . a:minor . '/x86_64-darwin', 'p')
  call mkdir(root . '/' . a:minor . '/x86_64-darwin', 'p')
  call mkdir(s:mise_data . '/installs/ruby/' . a:version . '/bin', 'p')
  call writefile([
        \ '#!/bin/sh',
        \ 'printf "' . a:version . '"',
        \ ], s:mise_data . '/installs/ruby/' . a:version . '/bin/ruby')
  call setfperm(s:mise_data . '/installs/ruby/' . a:version . '/bin/ruby', 'rwxr-xr-x')
endfunction

function! s:Run() abort
  call mkdir(s:home, 'p')
  call mkdir(s:project . '/app/models', 'p')
  call mkdir(s:bin, 'p')
  call writefile(['[tools]', 'ruby = "3.1.2"'], s:home . '/mise.toml')
  call s:InstallRuby('3.1.2', '3.1.0')
  call s:InstallRuby('4.0.2', '4.0.0')
  call writefile(['ruby-4.0.2'], s:project . '/.ruby-version')
  call writefile([], s:mise_log)
  call writefile(['class Widget', 'end'], s:project . '/app/models/widget.rb')
  call writefile([
        \ '#!/bin/sh',
        \ 'PROJECT_ROOT=' . shellescape(s:project),
        \ 'MISE_DATA=' . shellescape(s:mise_data),
        \ 'if [ -n "$MISE_TEST_LOG" ]; then printf "%s %s\n" "$PWD" "$*" >> "$MISE_TEST_LOG"; fi',
        \ 'if [ "$1" = "current" ] && [ "$2" = "ruby" ]; then',
        \ '  case "$PWD" in',
        \ '    "$PROJECT_ROOT"|"$PROJECT_ROOT"/*) printf "%s\n" "4.0.2" ;;',
        \ '    *) printf "%s\n" "3.1.2" ;;',
        \ '  esac',
        \ '  exit 0',
        \ 'fi',
        \ 'if [ "$1" = "env" ]; then',
        \ '  dir="$PWD"',
        \ '  while [ "$#" -gt 0 ]; do',
        \ '    if [ "$1" = "--cd" ]; then shift; dir="$1"; fi',
        \ '    shift',
        \ '  done',
        \ '  case "$dir" in',
        \ '    "$PROJECT_ROOT"|"$PROJECT_ROOT"/*) ver=4.0.2 ;;',
        \ '    *) ver=3.1.2 ;;',
        \ '  esac',
        \ '  printf "export MISE_RUBY_VERSION=%s\n" "$ver"',
        \ '  printf "export PATH=%s/installs/ruby/%s/bin:%s\n" "$MISE_DATA" "$ver" "$PATH"',
        \ '  exit 0',
        \ 'fi',
        \ 'exit 1',
        \ ], s:bin . '/mise')
  call setfperm(s:bin . '/mise', 'rwxr-xr-x')

  let $HOME = s:home
  let $MISE_DATA_DIR = s:mise_data
  let $PATH = s:mise_data . '/installs/ruby/3.1.2/bin:' . s:bin . ':' . $PATH
  let $RUBYLIB = ''
  let $MISE_TEST_LOG = s:mise_log
  unlet! $MISE_RUBY_VERSION
  let g:mise_auto = 1
  let g:mise_interval = 100000
  let g:mise_silent_load = 1
  let &runtimepath = &runtimepath . ',' . s:repo

  filetype off
  execute 'cd ' . fnameescape(s:home)
  runtime plugin/mise.vim
  call assert_true(exists('g:loaded_mise'), 'mise.vim should load with fake mise executable')
  doautocmd VimEnter
  call assert_equal([], readfile(s:mise_log), 'VimEnter should not query mise Ruby paths')
  filetype plugin on
  execute 'edit ' . fnameescape(s:project . '/app/models/widget.rb')

  let ruby4_site = s:mise_data . '/installs/ruby/4.0.2/lib/ruby/site_ruby/4.0.0'
  let ruby3_site = s:mise_data . '/installs/ruby/3.1.2/lib/ruby/site_ruby/3.1.0'
  call assert_equal('ruby', &filetype)
  call assert_match('env --quiet --cd', join(readfile(s:mise_log), "\n"), 'ruby ftplugin should synchronously export mise env before bundler runs')
  call assert_equal(0, stridx($PATH, s:mise_data . '/installs/ruby/4.0.2/bin'), '$PATH should prefer the project Ruby for bundle.vim')
  call assert_equal('4.0.2', system('ruby -e ' . shellescape('print RUBY_VERSION')), 'bundle.vim should resolve ruby from the project mise env')
  call assert_equal('4.0.2', get(b:, 'ruby_version', ''), 'ruby buffers should use the project mise Ruby')
  call assert_true(stridx(&l:path, ruby4_site) >= 0, '&path should include Ruby 4.0.2 paths')
  call assert_true(stridx(&l:path, ruby3_site) < 0, '&path should not keep the home Ruby 3.1.2 paths')
  call assert_true(stridx(&l:tags, ruby4_site . '/tags') >= 0, '&tags should include Ruby 4.0.2 tags')
endfunction

try
  call s:Run()
finally
  call delete(s:tmp, 'rf')
endtry

if !empty(v:errors)
  for error in v:errors
    echom error
  endfor
  cquit
endif

qa!
