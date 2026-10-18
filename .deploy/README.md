# Configuration deployer

Configuration and its deployer live together. A Git checkout and Python 3.10+
are sufficient to install configuration on Linux or Windows; `scripts` is not
required. Windows needs Developer Mode or permission to create symbolic links.

```sh
python3 .deploy/deploy.py plan
python3 .deploy/deploy.py apply
python3 .deploy/deploy.py check
```

Run these commands from the checkout root; the deployer locates that root
relative to its own file, so callers can also use an absolute path from any
working directory. On Windows use `py -3` instead of `python3`.

Linux's root `install.sh` runs the same deployer, then calls the optional
application installers in `.install/`. Those also need curl and the applications.
The separate Windows bootstrap installs system prerequisites and then calls
this repository's deployer.

## Placement conventions

Every non-hidden top-level directory is a package. Root files are repository
utilities/documentation and are never installed.

* `vim/.vimrc` installs as `~/.vimrc` on either platform.
* `ssh/.linux/.ssh/config` installs as `~/.ssh/config` only on Linux.
* `vim/.windows/_vimrc` installs as `~/_vimrc` only on Windows.
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

Root files and hidden root directories such as `.deploy` and `.install`
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
python3 -B -m unittest discover -s .deploy/tests
```

Tests live with this deployer and use temporary Git repositories and homes.
They cover source edits, repeated deployment, conflicts, platform overrides,
repository aliases and migration of old directory links.

## Alternatives Considered

* Keeping GNU Stow on Linux and separate PowerShell link handling preserves two
  implementations with different conflict and rerun behavior.
* A maintained source/destination manifest duplicates information already
  represented by directories and becomes another list to update.
* Putting the deployer in `scripts` would prevent this checkout from installing
  itself when that separate repository is absent.

The repository-local Python deployer provides one implementation and a small
placement convention without introducing another configuration manager.
