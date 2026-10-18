# Configuration setup

Setup, deployment and their tests live together here. A Git checkout and Python 3.10+
are sufficient to install configuration on Linux or Windows; `scripts` is not
required. Windows needs Developer Mode or permission to create symbolic links.

```sh
python3 install.py
python3 install.py --config-only
```

Run these commands from the checkout root; setup locates that root
relative to its own file, so callers can also use an absolute path from any
working directory. On Windows use `py -3` instead of `python3`.

The root `install.py` forwards to this directory's `install.py`, which checks
prerequisites, deploys configuration and discovers application setup for the
current platform. `bash install.sh` remains a thin compatibility wrapper.
`--config-only` requires only Git and Python; application setup also needs Bash,
curl and the applications themselves. `--home`, `--backup` and `--root` are
forwarded to deployment, and `BACKUP_DIR` remains supported.
Use `--config-only` with `--home` when preparing another home; application setup
can change account settings such as the login shell and targets the current account.

## Responsibilities

* `install.py`: common setup order, prerequisite checks and error reporting.
* `deploy.py`: placement rules, links, conflicts and source migration.
* `linux/*.sh`: Vim plugins/CoC, tmux plugins and initial Zsh setup. These can
  also be run individually after configuration deployment.
* `tests/`: setup and deployment tests.

The separate `scripts` repository installs system prerequisites, credentials,
fonts and services. Its Windows bootstrap calls this same Python setup with
`--config-only`, then prepares the native applications.

For deployment operations on their own:

```sh
python3 .setup/deploy.py plan
python3 .setup/deploy.py apply
python3 .setup/deploy.py check
```

## Placement conventions

Every non-hidden top-level directory is a package. Root files are repository
utilities/documentation and are never installed.

* `vim/.vimrc` installs as `~/.vimrc` on either platform.
* `ssh/.linux/.ssh/config` installs as `~/.ssh/config` only on Linux.
* `vim/.windows/_vimrc` installs as `~/_vimrc` only on Windows.
* Windows-only tmux and Vim helpers also live beneath `.windows`, even when
  the installed location is a familiar `.tmux/` or `.vim/` directory. A filename
  extension does not determine its platform; the Git Bash helper for native Vim
  belongs to Windows.
* A platform subtree overrides a shared file targeting the same destination.
  Two packages targeting the same location at the same priority are an error.
* A leading `@DOCUMENTS`, `@LOCALAPPDATA`, or `@APPDATA` selects that operating
  system directory. For example,
  `powertoys/.windows/@LOCALAPPDATA/Microsoft/PowerToys/settings.json` installs
  into LocalAppData. Actual settings live at these source locations.
* Repository symlinks reuse a source when it has multiple installed locations.
  They also work with Git for Windows checkouts that materialize symlinks as
  text. There is no separate tree of aliases duplicating the package inventory.
* A directory named `skills.links` installs its tracked immediate children
  into `skills/` as directory links. Adding a tracked skill adds its link without
  changing the deployer. Ordinary directories stay real, with individual file
  links, so caches and other application writes stay outside Git.

The tool uses `git ls-files`, not `.gitignore` matching, to discover authored
files. Existing ignore rules are unchanged: new ignored configuration still
needs `git add -f`. Runtime files untracked by Git are never independently
selected for deployment. A deliberately linked directory exposes that whole
source directory, allowing edits and new helpers through its installed path.

Root files and hidden root directories such as `.setup`
are repository utilities, not packages. Everything tracked under a package is
deployed according to its placement. There are no deployment ignore files or
special application exclusions.

## Deployment behavior

No manifest, installation database, timestamps, or generated inventory is kept.
The current source layout, Git index and installed links determine the result.
Correct links are untouched. Identical copies may become links; differing files
or links stop the complete plan before any configuration is installed. An
existing directory link is accepted when it resolves to the intended source.

For a reviewed, explicit migration, `--replace-existing --backup PATH` preserves
displaced destinations before relinking. Directory copies require a backup.
Normal installation never copies configuration as a fallback. Deployment after
a source move repairs dangling links that point into this repository.

`migrate --backup PATH` also unfolds old directory links owned by this checkout.
Tracked files remain linked to their sources; untracked runtime data moves out
of the repository into the real application directory. It backs up obsolete
source links found in the current deployment directories. It does not traverse
unrelated directories in your home or require an old installation inventory.
Both installers use this operation, and an unchanged rerun creates no backups.

`--home PATH` deploys into another home. `--package NAME` limits the packages.
`--root NAME=PATH` overrides a destination root; a longer key such as
`LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState` can
redirect that subtree for an unpackaged Terminal installation. These are
invocation arguments, not a stored inventory. `plan --json` and `check --json`
provide the same discovered links for installers and readiness checks.

The shared Git config includes `~/.config/git/platform.conf`. Both platforms
link that file to their tracked platform settings. Credential helper choices
are configuration; authentication tokens and SSH private keys stay in their
existing credential stores and private directories.

Shared agent instructions and skill aliases live in `claude/.codex` and
`claude/.agents`. Both platforms discover them here; CLI installers do not
maintain a second set of links. Linux's Node CA helper is deployed from
`node/.linux/.config/node/ca-cert.sh`, and shells and installers source that
installed path.

## Tests

```sh
python3 -B -m unittest discover -s .setup/tests
```

Tests live with the setup code and use temporary Git repositories and homes.
They cover source edits, repeated deployment, conflicts, platform overrides,
repository aliases and migration of old directory links.
Installer checks also cover the Bash wrapper, prerequisite failures, preserved
exit codes, platform action selection and unchanged reruns.

## Alternatives Considered

* Keeping GNU Stow on Linux and separate PowerShell link handling preserves two
  implementations with different conflict and rerun behavior.
* A maintained source/destination manifest duplicates information already
  represented by directories and becomes another list to update.
* Putting the deployer in `scripts` would prevent this checkout from installing
  itself when that separate repository is absent.
* Rewriting every Linux shell command in Python would preserve the same
  platform-specific operations while making the change larger. Python owns the
  common decisions; small shell scripts retain the native application actions.

The repository-local Python deployer provides one implementation and a small
placement convention without introducing another configuration manager.
