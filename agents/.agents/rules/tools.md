# Reuse existing development tools

Applies when: Preparing a reusable script, rule, skill, or document, looking for an existing personal development tool, running commands across Windows and WSL, or accessing GitHub repositories and CI with gh.

Before creating a reusable tool or document, look for an existing owner and extend it when the purpose matches. Inspect the actual checkout on the execution host; personal scripts may be organized under `setup`, `numerics`, project directories or other purpose-specific locations.

Use `rg --files` and content searches to find candidates, then read their usage and prerequisites before invoking them. A tool installed on the local Windows account may be absent from WSL, a container or a remote host. Installing `rc_files` does not require a separate `scripts` checkout.

Keep reusable tools generic: discover volatile paths and versions on the target host, and fix the owning configuration or script when a connection is wrong. Keep current usage beside the tool rather than maintaining a duplicate inventory in agent instructions.

For GitHub, establish the repository owner and the credential identity before interpreting a private-repository 404 as absence or an outage. The Linux `rc_files` gh launcher selects a matching saved owner account per process; confirm `command -v gh` reaches the deployed launcher. For organization repositories, native Windows, or an explicit system-gh invocation, choose the intended saved login's token in the child process environment. Never print the token or change the global active account to satisfy one repository. Verify access to the repository and then read CI for the exact commit. SSH push success does not prove that the CLI's API identity has access.

For noninteractive Windows/WSL command blocks, discover the `scripts` checkout and use `tools/windows_wsl.py` with a local UTF-8 script file and an explicit target. Read `tools/README.md` for its input, path, and exit-status contract. Prefer this to constructing nested PowerShell / Bash command strings. For simple direct WSL commands, use `wsl.exe --exec` to bypass the configured shell. If the helper is unavailable, report that and use an explicit host-native script; do not assume this configuration installed `scripts`.
