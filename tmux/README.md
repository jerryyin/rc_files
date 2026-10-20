# Terminal multiplexer

Linux uses tmux and Windows uses native psmux. Both load the shared preferences in `.config/tmux/common.conf`; platform configuration owns shell and plugin integration. Run `python3 ~/rc_files/.setup --package tmux` to install and configure the package, or use `py -3 "$HOME/rc_files/.setup" --package tmux` on Windows.

The shared status bar and pane borders use explicit Gruvbox Material dark, hard colors. The terminal supplies the default background and ordinary application colors; SSH clients choose their own terminal palette. Reload the configuration with prefix, then `r` after editing.

## Mobile handling

After connecting over SSH, attach to the existing server session to read agent output and send instructions. A full-screen window per task works well on a phone. The same shortcuts work in tmux and psmux.

Backtick and Ctrl-b are both prefixes. Press a prefix, release it, then press the command key. Backtick remains convenient on a desktop; Ctrl-b fits a phone SSH app's Ctrl key and custom toolbar buttons. Press Ctrl-b twice to send a literal Ctrl-b to the application.

- **Next agent window:** prefix, then `n`.
- **Previous agent window:** prefix, then `p`.
- **Choose an agent window:** prefix, then `w`; select an entry and press Enter.
- **Jump to a window:** prefix, then its number (`0`â€“`9`).
- **Label a task:** prefix, then comma; enter a short name such as `rc-files`, `scripts`, or `build`.
- **Detach while work continues:** prefix, then `d`; reconnect and attach again later.

In ShellDrop, custom toolbar keys can send Ctrl-b followed by `n`, `p`, or `w`, making these actions available without opening the iPhone symbol keyboard. Its [FAQ](https://shelldrop.sh/faq/) describes toolbar customization and swipe scrolling. Mouse mode is enabled on the server; gestures still depend on the SSH app.

Below 80 terminal columns, the status bar hides the session name, date, time, and hostname to leave space for window numbers and names. At 80 columns and wider, it shows the full status bar. The active window stays highlighted. F10 passthrough still displays `OFF` and passes both prefix keys through until F10 is pressed again.

To reload changes in an existing session, press the currently active prefix followed by `r`. You can also run `tmux source-file ~/.tmux.conf` on Linux or `psmux source-file "$HOME/.psmux.conf"` in Windows PowerShell. The new Ctrl-b prefix becomes available after reloading.
