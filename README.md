# rc_files

Configuration and its deployer live together. A Git checkout and Python 3.10+
are sufficient to install configuration on Linux or Windows; `scripts` is not
required. Windows needs Developer Mode or permission to create symbolic links.

```sh
python3 deploy.py plan
python3 deploy.py apply
python3 deploy.py check
```

On Windows use `py -3` instead of `python3`. Linux's `install.sh` runs the same
deployer, then prepares Vim, tmux and Zsh. It also needs Git, curl and those
applications. The separate Windows bootstrap installs system prerequisites and
then calls this repository's deployer.

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
* A directory alias named `skills.links` installs its tracked immediate children
  into `skills/` as directory links. Adding a tracked skill adds its link without
  changing the deployer. Ordinary directories stay real, with individual file
  links, so caches and other application writes stay outside Git.

The tool uses `git ls-files`, not `.gitignore` matching, to discover authored
files. Existing ignore rules are unchanged: new ignored configuration still
needs `git add -f`. Runtime files untracked by Git are never independently
selected for deployment. A deliberately linked directory exposes that whole
source directory, allowing edits and new helpers through its installed path.

README/license files, editor backups, and deployment ignore files are excluded.
Per-package `.deploy-ignore` and existing `.stow-local-ignore` files contain
Python regular expressions, one per line; blank lines and comments are ignored.
`lib/` uses its existing ignore file to keep helpers repository-local.

## Deployment behavior

No manifest, installation database, timestamps, or generated inventory is kept.
The current source layout, Git index and installed links determine the result.
Correct links are untouched. Identical copies may become links; differing files
or links stop the complete plan before any configuration is installed. An
existing directory link is accepted when it resolves to the intended source.

For a reviewed, explicit migration, `--replace-existing --backup PATH` preserves
displaced destinations before relinking. Directory copies require a backup.
Normal installation never copies configuration as a fallback. Deployment after
a source move repairs dangling links that point into this repository. Obsolete links
with no current destination are not removed by scanning your home directory.

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

## Alternatives Considered

* Keeping GNU Stow on Linux and separate PowerShell link handling preserves two
  implementations with different conflict and rerun behavior.
* A maintained source/destination manifest duplicates information already
  represented by directories and becomes another list to update.
* Putting the deployer in `scripts` would prevent this checkout from installing
  itself when that separate repository is absent.

The repository-local Python deployer provides one implementation and a small
placement convention without introducing another configuration manager.
