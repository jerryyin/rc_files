# Shared Vim configuration

`.vimrc` is the entry point on Linux and Windows. It resolves this checkout
through symlinks and sources `.vim/config` directly. Theme, mappings, plugin
choices and CoC extension choices are shared. Linux keeps its current commands
and plugins; native Windows selects its dependencies with `has('win32')`.

## Windows

The PowerShell bootstrap in `scripts/devenv/windows` installs native tools and
registered Python. Vim loads the shared `~/.vimrc` directly and discovers Python's
DLL itself. Windows settings and the AI process lookup helper live under
`vim/.windows/.vim/config`; their installed locations remain under `~/.vim/config`.

LeaderF uses the shared `.vim/config/leaderf-files.py` on both platforms for Git
files, generated build includes and project filters. Non-Git folders use ripgrep
or the existing `ag` and exclude `build/`. The custom listing needs Python, Git
and either search tool, and runs without Bash. `ai-processes.ps1` queries Windows
processes on demand for the `\cc` pane shortcut.

Windows uses native `clangd` with the existing generic CoC language-server
configuration and semantic tokens. Do not add `coc-clangd` on top of that
configuration: doing so would launch a second clangd. Project include paths and
compile commands must match the operating system where clangd runs.

## Linux

`python3 .setup vim` prepares vim-plug and CoC after the configuration has been
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
Platform settings and helpers are tracked. Plugin downloads, CoC extension
installs, caches and session files remain outside this checkout.
