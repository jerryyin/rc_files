# Codex

Normal setup installs or reuses the CLI and seeds missing local preferences from the tracked template. Existing `config.toml` remains application-owned; shared instructions come from the agents package. Native sign-in uses `codex login`.

For trusted Linux containers, `python3 ~/rc_files/.setup credentials --package codex --persistent-root /mounted/home` shares only `.codex/auth.json`. It does not share preferences, instructions, sessions, plugins or caches. A legacy whole-directory link becomes a local directory with preserved preferences and restored tracked instructions; all original persistent data remains in place.

Codex can use a file or the operating system credential store; file sharing applies only to file authentication. See [OpenAI authentication documentation](https://learn.chatgpt.com/docs/auth#credential-storage). If login or token refresh replaces the file link, save the new local file with the same command plus `--save`. A differing local login is preserved until explicitly saved. Windows keeps native authentication and does not import Linux login state.
