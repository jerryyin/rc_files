# Codex

Normal setup installs or reuses the CLI and seeds missing local preferences from the tracked template. Existing `config.toml` remains application-owned; shared instructions come from the agents package. Native sign-in uses `codex login`.

## Appearance

The template selects `tui.theme = "gruvbox-material"`. The native `.tmTheme` file in `.codex.links/themes/` uses the Gruvbox Material dark, hard palette, including Vim's purple string preference. Code blocks and diffs use this theme; inline code and local file paths explicitly use its muted green (`#a9b665`). See [OpenAI's theme documentation](https://learn.chatgpt.com/docs/cli-customization).

Codex 0.163.0 also derives session-title and footer colors from the selected theme. Selected controls use the theme's `codex.accent` rule (`#7daea3`). Ordinary web links retain Codex's fixed blue; success/failure indicators and block quotes use the connecting terminal's ANSI palette. Selecting the theme does not replace that SSH-client palette.

Setup links the dedicated themes directory to `~/.codex/themes`, keeping theme edits in the checkout. On an existing installation, run `/theme` and select the custom theme; setup preserves the existing local `config.toml`. Keep future-machine defaults in `.codex.config.toml.template`. The alternate screen remains disabled.

## Prompt input

Shift+Enter inserts a newline; plain Enter submits. Ctrl+j and Alt+Enter also insert a newline. These preferences use Codex's native editor keymap on both platforms. On an existing installation, copy `[tui.keymap.editor]` from the template into the local `~/.codex/config.toml` and restart Codex to load it.

## Credentials

For trusted Linux containers, `python3 ~/rc_files/.setup credentials --package codex --persistent-root /mounted/home` shares only `.codex/auth.json`. It does not share preferences, instructions, sessions, plugins or caches. A legacy whole-directory link becomes a local directory with preserved preferences and restored tracked instructions; all original persistent data remains in place.

Codex can use a file or the operating system credential store; file sharing applies only to file authentication. See [OpenAI authentication documentation](https://learn.chatgpt.com/docs/auth#credential-storage). If login or token refresh replaces the file link, save the new local file with the same command plus `--save`. A differing local login is preserved until explicitly saved. Windows keeps native authentication and does not import Linux login state.
