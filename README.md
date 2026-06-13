# mise.vim

`mise.vim` is a Vim/Neovim plugin that makes [mise][] work as a drop-in
replacement for [vim-rbenv][] style Ruby editing.

It tells the bundled [vim-ruby][] ftplugin where mise-managed Ruby installs
live, so Ruby buffers get project-correct `'path'` and `'tags'`. It also
synchronizes the editor environment before [vim-bundler][] computes gem
paths, so stdlib paths and bundled gem paths come from the same Ruby.

[mise]: https://mise.jdx.dev/
[vim-ruby]: https://github.com/vim-ruby/vim-ruby
[vim-rbenv]: https://github.com/tpope/vim-rbenv
[vim-bundler]: https://github.com/tpope/vim-bundler
[rbenv-ctags]: https://github.com/tpope/rbenv-ctags

## Behavior

- Resolves Ruby from the current buffer directory, not from the directory
  where Vim/Neovim was started.
- Honors nearby mise and Ruby version markers such as `.mise.toml`,
  `mise.toml`, `.ruby-version`, and `.tool-versions`.
- Reuses vim-ruby's existing `b:ruby_version`, `g:ruby_version_paths`, and
  `g:ruby_default_path` integration instead of replacing ruby ftplugin logic.
- Runs Ruby install path discovery lazily from Ruby buffers to keep startup
  work small.
- Keeps vim-bundler and vim-rails compatible by synchronously exporting
  `mise env --cd <project>` before bundler resolves gems.

This covers direct file starts such as:

    nvim /example/ruby/config.ru
    nvim /example/ruby/Gemfile

In both cases Ruby stdlib paths, `'path'`, `'tags'`, and vim-bundler gem
paths should all point at the same project Ruby.

## Installation

If you don't have a preferred installation method, I recommend installing
[pathogen.vim](https://github.com/tpope/vim-pathogen), and then simply copy
and paste:

    cd ~/.vim/bundle
    git clone git://github.com/jiz4oh/mise.vim.git

The plugin requires `mise` to be executable in Vim/Neovim's `$PATH`.

## Configuration

    " Disable automatic mise env export.
    let g:mise_auto = 0

    " Use a non-default mise executable.
    let g:mise_cmd = '/path/to/mise'

    " Tune async env export debounce for directory changes.
    let g:mise_interval = 500
    let g:mise_max_wait = 5

## Testing

Run the regression test with Vim:

    vim -Nu NONE -n -es -S test/mise_ruby.vim

Or with Neovim:

    XDG_RUNTIME_DIR=/private/tmp NVIM_LOG_FILE=/private/tmp/nvim-mise-test.log \
      nvim --headless -i NONE -Nu NONE -n -S test/mise_ruby.vim

The test uses a fake mise installation to verify that opening a Ruby buffer
from a different working directory switches both Ruby paths and bundled gem
resolution to the project Ruby.

## Inspiration

- [asdf.vim](https://github.com/jiz4oh/asdf.vim)
- [vim-rbenv](https://github.com/tpope/vim-rbenv)

## License

Distributed under the same terms as Vim itself.
See `:help license`.
