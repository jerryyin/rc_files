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

For full setup, install the selected applications and their prerequisites first. Each package's guide describes its requirements.

```sh
python3 .setup
```

Full setup deploys all selected configuration before running the selected packages' setup entries in package-name order. Each package owns its application commands and platform differences. Application setup runs on the target operating system. Windows package installation, fonts, Developer Mode, WSL and credentials belong to [scripts' Windows bootstrap](https://github.com/jerryyin/scripts/tree/main/devenv/windows); Linux system prerequisites belong to its `docker/env/min.sh`. Configuration setup remains independent of that repository.

## Placement conventions

Every non-hidden top-level directory is a package. Root files and hidden root directories, including `.setup`, are repository utilities and are not installed.

- A package mirrors its destination: `vim/.vimrc` installs as `~/.vimrc` on both platforms.
- `README.md` at a package root describes that package and is excluded from deployment, including at the root of a platform subtree. Markdown within configuration trees keeps its normal destination; agent instructions, rules and skills are installed content.
- A package's `.setup/` directory contains its installation code and is excluded from deployment. An optional tracked `.setup/__main__.py` is its sole setup entry, shared across platforms. Runtime and untracked files do not register setup entries.
- `.linux` and `.windows` subtrees select platform content. For example, `ssh/.linux/.ssh/config` installs only on Linux. Platform content overrides a shared file with the same destination; equal-priority conflicts between packages are errors.
- A leading `@DOCUMENTS`, `@LOCALAPPDATA` or `@APPDATA` selects that operating system directory. Remaining path components keep their normal meaning.
- Tracked repository symlinks reuse a source at multiple destinations. Setup resolves their final source, including aliases materialized as text by Git for Windows.
- A directory ending in `.links` installs its tracked immediate children as directory links, removing the suffix at the destination. For example, `skills.links/review/` becomes `skills/review/`. Ordinary directories remain real directories containing individual file links, keeping application runtime writes outside Git.

Discovery uses the Git index. Stage intended new configuration before deploying it; ignored authored files need `git add -f`. Existing ignore rules still exclude generated files. A deliberately linked directory exposes its whole source directory, so new helpers created through an installed skill directory also reach the checkout.

The source layout supplies placement; there is no separate manifest or installation database. See [agent configuration](../agents/README.md) for shared instruction and skill ownership.

## Conflicts and migration

Correct links are left untouched. `apply` checks the complete selected plan for conflicts before installing configuration. Identical file copies can become links; differing files and unrelated links require review. Normal installation never falls back to copying configuration.

```sh
python3 .setup apply --package vim
python3 .setup apply --replace-existing --backup /path/to/backup
python3 .setup migrate --backup /path/to/backup
```

Use `--replace-existing` only after reconciling local edits; it requires a backup destination. Directory copies also require a backup. `migrate` handles the complete package tree: it unfolds old source-owned directory links, moves untracked application data into real destination directories, and retires obsolete links owned by this checkout. Unfolding can happen before later conflict reporting.

Full setup, including `--config-only`, uses migration and selects a timestamped backup under `~/.dotfiles-backup` unless `--backup` or `BACKUP_DIR` supplies one. With `--package`, setup applies only the selected packages and leaves other packages' links alone; complete-tree migration remains an explicit separate operation. An unchanged rerun leaves correct links alone and creates no redundant backups. Moved sources and tracked aliases are repaired from the current layout.

## Application maintenance

Select packages to link their configuration and run their setup as needed:

```sh
python3 .setup --package vim
python3 .setup --package tmux
python3 .setup --package zsh
python3 .setup --package vim --update
python3 .setup --package tmux --update
```

Each package decides which platforms it supports and what `--update` refreshes. `--config-only` skips every package setup entry. Application requirements, dependency choices and maintenance behavior belong with the package; see [Vim's guide](../vim/README.md) for an example.

The runner starts each tracked entry with its own Python interpreter and the entry's directory as the working directory, stopping on the first failed process. Entries locate their source files relative to `__file__` and use the inherited environment: `HOME` (also `USERPROFILE` on Windows), redirected XDG/application directories for another home, `RC_SETUP=1`, `RC_SETUP_UPDATE=0` or `1`, and `RC_SETUP_REDIRECTED=0` or `1`. The last flag lets an entry avoid touching a live account session when testing another home. Public Git downloads are noninteractive and ignore the account's global Git configuration. Entries own additional environment requirements, such as npm's certificate bundle. The shared runner has no application registry, dependency list or application-specific options.

Applications read their linked configuration directly. Reload or restart the application after editing its settings. System installers do not render a second configuration file.

### Alternatives considered

Keeping application calls in the central command would require changing it for every new application. A manifest describing installation commands would add another format alongside Python and native plugin declarations. A single optional Python entry per package keeps executable application decisions with their owner and lets package selection work without registration.

## Other destinations and checks

`plan`, `apply` and `check` accept repeated `--package NAME` selections. `--home PATH` selects another home; `--root NAME=PATH` redirects a destination root. A longer root key can redirect a subtree, such as an unpackaged Windows Terminal settings location. These are invocation arguments, not stored bookkeeping. Use `--help` for the full command interface.

`plan --json` and `check --json` expose discovered links for installers and readiness checks. Shared setup tests live in `tests/`; application tests live beside their package's setup. Tests use temporary repositories and homes. Run from the repository root with:

```sh
python3 -B -m unittest discover -s .setup/tests
python3 -B -m unittest discover -s vim/.setup/tests
python3 -B -m unittest discover -s tmux/.setup/tests
```
