# Reuse existing development tools

Applies when: Preparing a reusable script, rule, skill, or document, looking for an existing personal development tool, or running commands across Windows and WSL.

Before creating a reusable tool or document, look for an existing owner and extend it when the purpose matches. Inspect the actual checkout on the execution host; personal scripts may be organized under `setup`, `numerics`, project directories or other purpose-specific locations.

Use `rg --files` and content searches to find candidates, then read their usage and prerequisites before invoking them. A tool installed on the local Windows account may be absent from WSL, a container or a remote host. Installing `rc_files` does not require a separate `scripts` checkout.

Keep reusable tools generic: discover volatile paths and versions on the target host, and fix the owning configuration or script when a connection is wrong. Keep current usage beside the tool rather than maintaining a duplicate inventory in agent instructions.

For noninteractive Windows/WSL command blocks, discover the `scripts` checkout and use `tools/windows_wsl.py` with a local UTF-8 script file and an explicit target. Read `tools/README.md` for its input, path, and exit-status contract. Prefer this to constructing nested PowerShell / Bash command strings. For simple direct WSL commands, use `wsl.exe --exec` to bypass the configured shell. If the helper is unavailable, report that and use an explicit host-native script; do not assume this configuration installed `scripts`.
