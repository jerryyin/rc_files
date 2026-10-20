# Claude Code

This package reuses an installed Claude command or installs its npm CLI when missing, prepares Node as a dependency, and generates private settings during setup. Use the normal `claude` command. It adds no shell function, launcher or credential helper.

## Setup

```sh
python3 ~/rc_files/.setup --package claude
```

On Windows:

```powershell
py -3 "$HOME/rc_files/.setup" --package claude
```

The tracked template and generator live in `.setup/`; neither is deployed into the home directory. Setup reads the template and `~/vault/claude_key.txt`, then writes an ordinary, untracked `~/.claude/settings.json`. Generated files are restricted to the current user and, on Windows, SYSTEM and administrators. `CLAUDE_CONFIG_DIR` and `CLAUDE_KEY_FILE` can select other locations.

Fresh setup seeds the template preferences. Ordinary reruns preserve existing preferences, add missing defaults and update the subscription header from the vault, leaving other custom headers intact. Equivalent settings are not rewritten. Use `--package claude --update` to refresh template preferences while retaining settings absent from the template. Edit `.setup/settings.json.template` to keep preferences for future machines; edits to the generated local file are local to that machine.

Setup works before the vault is available: it seeds preferences and preserves any existing credentials. After syncing the vault or replacing its key, rerun the command above. Windows credential setup and Linux container credential setup also invoke this package once the configuration checkout is available. Container credential refresh passes `--no-install`, requiring the installed tools and preventing runtime package installation. An invalid key or settings file stops setup without changing the settings file or printing the key.

Claude owns its separate `.claude.json` state, onboarding, login and project information. Setup leaves that file alone. Existing source-owned settings links become ordinary files; unrelated links require reconciliation. Full configuration migration retires obsolete launcher and template links.

## Checks

```sh
python3 -B -m unittest discover -s claude/.setup/tests
```

Tests use temporary homes and fake credentials. They cover setup, key replacement, existing preferences and state, file ownership and deployment reruns. Set `RC_CLAUDE_CLI_TEST=1` to include the installed CLI check against a fake localhost gateway. No test contacts the AMD gateway.

## Alternatives considered

A launch wrapper requires shell integration and process handling on every invocation. A native credential helper adds a runtime callback and uses different authentication headers from the current gateway configuration. Generating private settings during setup keeps the normal CLI invocation and gives credentials an explicit local owner.
