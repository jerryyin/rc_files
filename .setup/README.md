# Configuration setup

This directory provides one Python command for linking this checkout's configuration and preparing application plugins on Linux and Windows. Git and Python 3.10+ are required. Windows also needs Developer Mode or permission to create symbolic links.

## Start here

Run from the repository root; an absolute path to `.setup` also works. On Windows, replace `python3` with `py -3`.

```sh
python3 .setup plan
python3 .setup --config-only
python3 .setup check
```

`plan` shows the discovered destinations. `--config-only` links configuration and migrates links from older layouts. `check` reports missing or detached links; it does not prove that an application loaded its settings.

For full setup, install the native applications and their prerequisites first, including npm for CoC:

```sh
python3 .setup
```

Full setup deploys configuration, prepares tmux/psmux and Vim plugins, then loads Zsh's plugin setup on Linux. Application setup runs on the target operating system. Windows package installation, fonts, Developer Mode, WSL and credentials belong to [scripts' Windows bootstrap](https://github.com/jerryyin/scripts/tree/main/devenv/windows); Linux system prerequisites belong to its `docker/env/min.sh`. Configuration-only setup remains independent of that repository.

## Placement conventions

Every non-hidden top-level directory is a package. Root files and hidden root directories, including `.setup`, are repository utilities and are not installed.

- A package mirrors its destination: `vim/.vimrc` installs as `~/.vimrc` on both platforms.
- `.linux` and `.windows` subtrees select platform content. For example, `ssh/.linux/.ssh/config` installs only on Linux. Platform content overrides a shared file with the same destination; equal-priority conflicts between packages are errors.
- A leading `@DOCUMENTS`, `@LOCALAPPDATA` or `@APPDATA` selects that operating system directory. Remaining path components keep their normal meaning.
- Tracked repository symlinks reuse a source at multiple destinations. Setup resolves their final source, including aliases materialized as text by Git for Windows.
- A directory ending in `.links` installs its tracked immediate children as directory links, removing the suffix at the destination. For example, `skills.links/review/` becomes `skills/review/`. Ordinary directories remain real directories containing individual file links, keeping application runtime writes outside Git.

Discovery uses the Git index. Stage intended new configuration before deploying it; ignored authored files need `git add -f`. Existing ignore rules still exclude generated files. A deliberately linked directory exposes its whole source directory, so new helpers created through an installed skill directory also reach the checkout.

The source layout supplies placement; there is no separate manifest or installation database. See [agent configuration](agents.md) for shared instruction and skill ownership.

## Conflicts and migration

Correct links are left untouched. `apply` checks the complete selected plan for conflicts before installing configuration. Identical file copies can become links; differing files and unrelated links require review. Normal installation never falls back to copying configuration.

```sh
python3 .setup apply --package vim
python3 .setup apply --replace-existing --backup /path/to/backup
python3 .setup migrate --backup /path/to/backup
```

Use `--replace-existing` only after reconciling local edits; it requires a backup destination. Directory copies also require a backup. `migrate` handles the complete package tree: it unfolds old source-owned directory links, moves untracked application data into real destination directories, and retires obsolete links owned by this checkout. Unfolding can happen before later conflict reporting.

Full setup, including `--config-only`, uses migration and selects a timestamped backup under `~/.dotfiles-backup` unless `--backup` or `BACKUP_DIR` supplies one. An unchanged rerun leaves correct links alone and creates no redundant backups. Moved sources and tracked aliases are repaired from the current layout.

## Application maintenance

After configuration deployment, run individual application setup as needed:

```sh
python3 .setup vim
python3 .setup mux
python3 .setup shell
python3 .setup vim --update
python3 .setup mux --update
```

The `shell` action prepares Zsh plugins on Linux. Plugin choices stay in the native application configuration. Existing Vim and mux plugins are retained unless `--update` is requested; CoC checks the latest versions of both tracked extension choices and existing package dependencies on every setup, preserving local additions.

Vim and tmux/psmux load their linked configuration directly. Reload or restart the application after editing its settings. System installers do not render a second configuration file. See [Vim's guide](vim.md) for editor maintenance.

## Other destinations and checks

`plan`, `apply` and `check` accept repeated `--package NAME` selections. `--home PATH` selects another home; `--root NAME=PATH` redirects a destination root. A longer root key can redirect a subtree, such as an unpackaged Windows Terminal settings location. These are invocation arguments, not stored bookkeeping. Use `--help` for the full command interface.

`plan --json` and `check --json` expose discovered links for installers and readiness checks. The setup tests live in `tests/`, use temporary repositories and homes, and run from the repository root with:

```sh
python3 -B -m unittest discover -s .setup/tests
```
