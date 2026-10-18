# Shared Vim configuration

`.vimrc` is the entry point on Linux and Windows. It resolves this checkout
through symlinks and sources `.vim/config` directly. Theme, mappings, plugin
choices and CoC extension choices are shared. Linux keeps its current commands
and plugins; native Windows selects its dependencies with `has('win32')`.

## Windows

The PowerShell bootstrap in `scripts/devenv/windows` installs native tools and
links `%USERPROFILE%\_vimrc` to `vim/.windows/_vimrc`, which reads the discovered
Git Bash and Python locations and sources this vimrc. `config/windows.vim` contains OS settings.
Python's DLL is discovered by the bootstrap rather than hardcoded in Vim.

Windows uses native `clangd` with the existing generic CoC language-server
configuration and semantic tokens. Do not add `coc-clangd` on top of that
configuration: doing so would launch a second clangd. Project include paths and
compile commands must match the operating system where clangd runs.

## Linux

`.install/vim.sh` prepares vim-plug and CoC after the configuration has been
deployed. Gutentags remains enabled when its tools are available. The root
`.notags` marker suppresses tags inside this checkout; `gtags/.notags` supplies
the installed home marker. These files belong to Gutentags, not the deployer.

`config/plugins.vim` is used both by Vim and the Windows plugin installer.
`coc-extensions.json` supplies the extension choices for Vim, Neovim and both
platforms' installers.
Windows uses built-in syntax rather than Polyglot, whose unnamed-buffer handler
currently fails there. LeaderF runs in Python mode without the Unix build hook.
Native search/multiplexer commands are `rg` and `psmux`, selected in the same
mapping definitions used for `ag` and `tmux` on Linux. Ctags is not installed by
the Windows bootstrap; Windows outlines use CoC.

Pull this repository and restart Vim to load new settings; no configuration
copy or separate platform vimrc needs refreshing. Plugin updates remain under
vim-plug (`:PlugUpdate`) and CoC (`:CocUpdate`).

Keep the existing Git ignore policy. Intentionally authored files under `.vim`
are added explicitly with `git add -f`; there are no broad ignore exceptions.
The Windows loader is tracked. Discovered paths, plugin downloads, CoC extension
installs, caches and session files remain outside this checkout.
