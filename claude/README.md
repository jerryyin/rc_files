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

The tracked template and generator live in `.setup/`; neither is deployed into the home directory. Normal setup reads only the public template and writes an ordinary, untracked `~/.claude/settings.json`. Generated files are restricted to the current user and, on Windows, SYSTEM and administrators. `CLAUDE_CONFIG_DIR` and `CLAUDE_KEY_FILE` can select other locations.

Fresh setup seeds the template preferences. Ordinary reruns preserve existing preferences, add missing defaults and leave existing credentials intact. Equivalent settings are not rewritten. Use `--package claude --update` to refresh template preferences while retaining settings absent from the template. Edit `.setup/settings.json.template` to keep preferences for future machines; edits to the generated local file are local to that machine.

Normal setup never reads the vault. After making the vault available or replacing its key, apply credentials explicitly:

```sh
python3 ~/rc_files/.setup credentials --package claude
```

This reads `~/vault/claude_key.txt` and updates only its subscription header, preserving other custom headers and preferences. `--vault PATH` or `CLAUDE_KEY_FILE` selects another source. Missing keys leave the local settings unchanged. Windows credential setup and Linux container startup call the same credential phase after preparing the vault; it runs no installers. An invalid key or settings file stops the hook without changing the settings file or printing the key.

Claude owns its separate `.claude.json` state, onboarding, login and project information. Setup leaves that file alone. Existing source-owned settings links become ordinary files; unrelated links require reconciliation. Full configuration migration retires obsolete launcher and template links.

## Appearance

The public template selects `custom:gruvbox-material`. The native JSON theme in `.claude.links/themes/` supplies the Gruvbox Material dark, hard palette for interface accents and subtle diff backgrounds. Syntax highlighting stays enabled, and the existing scrolling renderer stays selected. See [Claude's native theme support](https://code.claude.com/docs/en/terminal-config#create-a-custom-theme).

Setup links the whole dedicated themes directory to `~/.claude/themes`, so edits and newly created themes stay in the checkout even when Claude replaces a theme file while saving. Edit the source or use `/theme` to preview and edit it. New theme files still need explicit staging. Theme selection itself is a local preference; update `.setup/settings.json.template` to carry a different default to future machines. Restart Claude after first deploying the directory; subsequent theme-file edits reload automatically.

## Checks

```sh
python3 -B -m unittest discover -s claude/.setup/tests
```

Tests use temporary homes and fake credentials. They cover setup, key replacement, existing preferences and state, file ownership and deployment reruns. Set `RC_CLAUDE_CLI_TEST=1` to include the installed CLI check against a fake localhost gateway. No test contacts the AMD gateway.

## Alternatives considered

A launch wrapper requires shell integration and process handling on every invocation. A native credential helper adds a runtime callback and uses different authentication headers from the current gateway configuration. Seeding public defaults during setup and applying secrets only in the credential phase keeps the normal CLI invocation and gives credentials an explicit local owner.
