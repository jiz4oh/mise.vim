# Agent 工作说明

## 包管理器

- 本仓库是小型 Vimscript 插件，当前没有包管理器、构建系统或 CI 配置。
- 依赖运行环境中的 `mise`、Vim/Neovim，以及外部插件接口：vim-ruby、vim-bundler、vim-rails。

## 文件级命令

- 查看状态：`git status --short --branch -uall`
- 运行 Vim 回归测试：`vim -Nu NONE -n -es -S test/mise_ruby.vim`
- 运行 Neovim 回归测试：
  ```sh
  XDG_RUNTIME_DIR=/private/tmp NVIM_LOG_FILE=/private/tmp/nvim-mise-test.log \
    nvim --headless -i NONE -Nu NONE -n -S test/mise_ruby.vim
  ```
- 检查空白问题：`git diff --check && git diff --cached --check`

## 关键约定

- 这是 `vim-rbenv` 风格的 mise 替代插件；优先复用 Vim/Neovim bundled ruby ftplugin 的 `b:ruby_version`、`g:ruby_version_paths`、`g:ruby_default_path` 机制。
- 必须兼容 vim-bundler 和 vim-rails。改 Ruby 版本解析时，要同时验证 Ruby stdlib paths、`&path`、`&tags`、bundler gem paths 都来自同一项目 Ruby。
- 不要把启动目录当项目目录；所有 Ruby buffer 行为都应按 buffer 文件路径向上查找最近的 mise/Ruby marker。
- 避免增加启动期开销。Ruby install path 扫描和同步 `mise env --cd` 应尽量在 Ruby buffer 需要时触发。
- 提交信息使用 Conventional Commits。bugfix、refactor、feature 分开提交；一个提交只承载一个可验证意图。

## 精准修改

- 对 bug fix 先补或更新 `test/mise_ruby.vim`，确认旧行为会失败，再改实现。
- 修改 `autoload/mise/env.vim` 时同时考虑 Vim 和 Neovim job/systemlist API 差异。
- 修改 `ftplugin/ruby.vim` 时注意加载顺序：bundled ruby ftplugin 可能已经设置 `b:ruby_version`，mise 仍需修正 env、`&path` 和 `&tags`。
- 不要写入一次性排障结论；长期维护规则放这里，场景复现和事故细节放 README 或独立文档。

## AGENTS 维护

- 当 README、测试命令、插件兼容边界或加载顺序策略变化时，同步更新本文件。
- 保持本文件短而可执行；删除过时命令，不追加背景叙事。
