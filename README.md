# mise.vim

It tells recent versions of [vim-ruby][] where your Ruby
installs are located, so that it can set `'path'` and [`'tags'`][rbenv-ctags]
in your Ruby buffers to reflect the nearest `.mise.toml` or `.ruby-version` file.

[vim-ruby]: https://github.com/vim-ruby/vim-ruby
[rbenv-ctags]: https://github.com/tpope/rbenv-ctags

## Installation

If you don't have a preferred installation method, I recommend
installing [pathogen.vim](https://github.com/tpope/vim-pathogen), and
then simply copy and paste:

    cd ~/.vim/bundle
    git clone git://github.com/jiz4oh/mise.vim.git

## Inspiration

- [asdf.vim](https://github.com/jiz4oh/asdf.vim)
- [vim-rbenv](https://github.com/tpope/vim-rbenv)

## License

Distributed under the same terms as Vim itself.
See `:help license`.

