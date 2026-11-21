# Terminal multiplexer

Linux uses tmux and Windows uses native psmux. Both load the shared preferences in `.config/tmux/common.conf`; platform configuration owns shell and plugin integration. Run `python3 ~/rc_files/.setup --package tmux` to install and configure the package, or use `py -3 "$HOME/rc_files/.setup" --package tmux` on Windows.

The shared status bar and pane borders use explicit Gruvbox Material dark, hard colors. The terminal supplies the default background and ordinary application colors; SSH clients choose their own terminal palette. Reload the configuration with prefix, then `r` after editing.

Interactive Windows SSH logins automatically attach to `main` (creating it when absent). Detaching returns to PowerShell. Command-only SSH calls and shells already inside psmux do not auto-attach. Windows Terminal still starts at PowerShell; run `tmux` or `dev` there. The SSH client controls its own font and terminal palette.

## Mobile handling

After connecting over SSH, attach to the existing server session to read agent output and send instructions. A full-screen window per task works well on a phone. The same shortcuts work in tmux and psmux.

Backtick and Ctrl-b are both prefixes. Press a prefix, release it, then press the command key. Backtick remains convenient on a desktop; Ctrl-b fits a phone SSH app's Ctrl key and custom toolbar buttons. Press Ctrl-b twice to send a literal Ctrl-b to the application.

- **Next agent window:** prefix, then `n`.
- **Previous agent window:** prefix, then `p`.
- **Choose an agent window:** prefix, then `w`; select an entry and press Enter.
- **Jump to a window:** prefix, then its number (`0`–`9`).
- **Label a task:** prefix, then comma; enter a short name such as `rc-files`, `scripts`, or `build`.
- **Detach while work continues:** prefix, then `d`; reconnect and attach again later.

In ShellDrop, custom toolbar keys can send Ctrl-b followed by `n`, `p`, or `w`, making these actions available without opening the iPhone symbol keyboard. Its [FAQ](https://shelldrop.sh/faq/) describes toolbar customization and swipe scrolling. Mouse mode is enabled on the server; gestures still depend on the SSH app.

Below 80 terminal columns, the status bar hides the session name, date, time, and hostname to leave space for window numbers and names. At 80 columns and wider, it shows the full status bar. The active window stays highlighted. F10 passthrough still displays `OFF` and passes both prefix keys through until F10 is pressed again.

To reload changes in an existing session, press the currently active prefix followed by `r`. You can also run `tmux source-file ~/.tmux.conf` on Linux or `psmux source-file "$HOME/.psmux.conf"` in Windows PowerShell. The new Ctrl-b prefix becomes available after reloading.

## Resizing panes

Prefix, then `t` enters resize mode, and the status bar shows `RESIZE`. In resize mode, `h`, `j`, `k`, and `l` move the pane edge in larger steps. Use `H`, `J`, `K`, and `L` for finer adjustments. Press Escape, Enter, or `q` to leave.

Press the prefix, then `=` to equalize the top-row columns while preserving stacked panes and their heights. In resize mode, press `=` on its own and continue resizing. To open the paste-buffer chooser, use the prefix, then `:` and enter `choose-buffer`.

## Ask about selected agent output

In a Claude Code or Codex pane, press the prefix and then `[` to enter copy mode. Move to the passage, press `Space` to begin selecting (or `V` for whole lines), extend the selection, then press `a` to ask beside the source or `s` to ask below it. Type your question at `Question>`. Each question runs in a temporary fork of the source conversation. Follow-ups include the earlier answers. Press Enter on an empty line to close and return to the source pane.

With `a`, the first question splits a neighbouring pane when available. On its own, the source opens a right-hand popup on Linux tmux or a right split on Windows psmux. With `s`, the answer takes the bottom 20% of the selected pane, like prefix-`s`. Repeating the shortcut reuses its answer pane while it is open. Both layouts use the same question helper.

Windows psmux shows the selected passage immediately. New Codex sessions publish their thread ID through the terminal title with `terminal_title = ["thread-id"]` under `[tui]`. For a session opened with the old settings, the helper looks up a submitted prompt visible in that pane or the selected answer in local Codex history. If the source is still ambiguous, it asks you to pick the conversation before sending the question.
