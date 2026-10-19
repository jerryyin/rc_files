# Vim configuration

Linux and Windows Vim share `vim/.vimrc`, installed as `~/.vimrc`. It resolves the checkout through its link and loads the configuration under `vim/.vim/config`. Native Windows settings live under `vim/.windows`; Linux Neovim configuration lives under `vim/.linux/.config/nvim`.

## Daily use

The leader key is backslash. Common navigation and review commands are:

- Ctrl-h/j/k/l move between Vim splits. Native Windows console Vim also accepts Ctrl-Backspace as left navigation because ConPTY can deliver Ctrl-h with that key identity inside psmux.
- `\gg` opens Fugitive's Git status view. Use `=` on a file to inspect its changes there.
- `\gd` compares the current file with `HEAD`, showing combined staged and unstaged changes. `:Gvdiffsplit` compares with the staged version. Use `:diffoff! | only` to leave the diff and close the other split windows.
- Termdebug enables `E`, `J`, `S`, `B`, `D` and `C` for evaluate, next, step, breakpoint, clear and continue during a debugging session, restoring previous global mappings when the session ends.

Mappings and their plugin settings are authored in the linked configuration files. Project build, test, formatting and debugging commands still require the project's toolchain on the execution host.

Diff backgrounds preserve syntax colors. Editors that support them use word-level change highlighting and similar-line alignment; older versions retain their supported behavior.

## Reviewing commits

`\gl` loads commit history; `:copen` displays the list. Select an entry and press Enter for its commit overview. Press Enter on a `diff --git` header to open that file's comparison.

- From the pane showing the reviewed commit, `dq` closes the comparison and `C` returns to that commit's overview at the current file.
- In the overview, `]/` and `[/` move between files. Press Enter to open the next comparison.
- In a comparison, `]c` and `[c` move between changed blocks.

Remember **d**iff **q**uit, **C**ommit, then `]/` for the next file. These are Normal-mode keys without a leader prefix.

`\g?` opens Fugitive's mapping help from any buffer. Inside a Fugitive buffer, `g?` shows general help and `d?` shows diff help. `:help fugitive-maps` opens the same reference directly.

Quickfix lists use their normal syntax. For a buffer containing ANSI-colored output, `\ea` explicitly toggles ANSI rendering.

## Installation and updates

After deploying the configuration, run the shared installer from the repository root. On Windows use `py -3` in place of `python3`.

```sh
python3 .setup --package vim
python3 .setup --package vim --update
```

[Plugin declarations](.vim/config/plugins.vim) and [CoC extension choices](.vim/coc-extensions.json) are the source of truth; [Vim's package setup](.setup/__main__.py) runs their installers. Native Vim and npm must be on `PATH`. Setup installs missing plugins; `--update` also refreshes existing plugins. CoC checks the latest selected extensions on every setup and retains local additions. Plugin downloads and extension installations stay outside Git.

C/C++ language services use the shared [CoC settings](.vim/coc-settings.json) and a native clangd. Compile commands, include paths and toolchains must match the host running clangd. Adding a second clangd extension alongside the configured server would duplicate it.

Gutentags remains available where its tools are installed. The root `.notags` excludes this checkout; `gtags/.notags` supplies the home marker. These are editor markers and remain tracked.

## Editing configuration

Edit through the installed links or directly in this checkout, then reload the affected configuration or restart Vim. Review changes in Git before updating another machine. New authored files under ignored configuration directories need explicit `git add -f`; caches, swap files, plugin code and sessions retain their application ownership.
