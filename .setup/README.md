# Configuration setup

Setup, deployment and their tests live together here. A Git checkout and Python 3.10+
are sufficient to install configuration on Linux or Windows; `scripts` is not
required. Windows needs Developer Mode or permission to create symbolic links.

```sh
python3 .setup
python3 .setup --config-only
```

This directory is the only command entry point. On Windows use `py -3 .setup`.
An absolute path works from any working directory. There are no root wrappers
or separate installation and deployment commands.

Full setup links configuration and prepares Vim, tmux/psmux and (on Linux) Zsh.
Install those applications and npm on `PATH` first; system prerequisites belong to the
separate `scripts` repository. `--config-only` needs only Git and Python.
Both full setup and configuration-only deployment can target another `--home`.
Setup does not change account settings. `BACKUP_DIR` remains supported.

## Responsibilities

* `__main__.py`: the single CLI, setup order and error reporting. It calls the
  other Python modules directly.
* `links.py`: generic placement rules, links, conflicts and source migration.
* `vim.py`: the same vim-plug and CoC installation on both platforms. Plugin
  choices remain in `vim/.vim/config/plugins.vim` and `coc-extensions.json`.
* `mux.py`: bootstrap TPM/PPM and invoke their native plugin installers in an
  isolated server. Plugin choices live in the native rc files.
* `context.py`: application paths and the explicit setup process environment.
* `tests/`: setup, placement and application tests.

Vimscript still calls vim-plug, Zsh still loads Zinit, and upstream plugin
managers retain their own languages. Native PowerShell runtime hooks stay
with their application configuration. Windows package installation, fonts,
Developer Mode, WSL, credentials and Linux login-shell selection stay in `scripts`.
Zsh loads its own Zinit plugins eagerly when `RC_SETUP=1`; Python sources the
installed `.zshrc` directly without transforming it.

For individual operations:

```sh
python3 .setup plan
python3 .setup apply
python3 .setup check
python3 .setup vim
python3 .setup mux
python3 .setup shell
```

`--update` refreshes existing Vim and mux plugins. vim-plug bootstraps itself
from `plugins.vim` during explicit setup; ordinary Vim startup does not download.
Vim discovers registered Python and Git for Windows without a machine-path file.
For CoC, Python passes shared choices and existing package dependencies to npm
at `latest`; npm owns the runtime package data, retaining local additions and
other fields. CoC's synchronous commands swallow install failures and skip
locked or disabled extensions, so they cannot enforce this setup policy.
Unchanged configuration and installed plugins are skipped.

Both tmux and psmux source `~/.config/tmux/common.conf` directly. The Linux
`.tmux.conf` and Windows `.psmux.conf` own terminal, clipboard and native plugin
differences. There is no translation or generated configuration to refresh.
Edits through the installed links reach Git and take effect on native reload.

The PowerShell profile invokes native tools on `PATH`. The Windows system
bootstrap adds Vim's installation directory to the account's `PATH`; redirected
test homes only change their process environment. No generated command-path file
is needed by the profile. The Unix-dependent Neovim configuration lives beneath
`vim/.linux`, and shares Vim's project-file listing helper.

## Placement conventions

Every non-hidden top-level directory is a package. Root files are repository
utilities/documentation and are never installed.

* `vim/.vimrc` installs as the single `~/.vimrc` entry on either platform.
* `ssh/.linux/.ssh/config` installs as `~/.ssh/config` only on Linux.
* Windows-only tmux and Vim helpers also live beneath `.windows`, even when
  the installed location is a familiar `.tmux/` or `.vim/` directory. A filename
  extension does not determine its platform; placement does.
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
Existing links through a tracked Git alias are redirected to its real source,
including aliases checked out as text files by Git for Windows.

`migrate --backup PATH` also unfolds old directory links owned by this checkout.
Tracked files remain linked to their sources; untracked runtime data moves out
of the repository into the real application directory. It backs up obsolete
source links found in deployment directories described by any tracked platform.
This also cleans up a former shared file after it becomes platform-specific.
It does not traverse unrelated directories in your home or require an old
installation inventory.
Full setup uses this operation, and an unchanged rerun creates no backups.

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

Shared agent instructions, conditional rules and personal skills live in `agents/.agents`. The `agents/.codex` and `agents/.claude` aliases reuse that source on both platforms; CLI installers do not maintain a second set of links. See [the agent configuration design](agents-plan.md) for tool entrypoints and loading checks. Migration also retires source-owned links in former configuration directories immediately below managed parents; unrelated files and deeper application runtime directories are preserved. Linux's Node CA helper is deployed from
`node/.linux/.config/node/ca-cert.sh`, and shells source that
installed path. Python setup uses the operating system CA bundle for npm when
NODE_EXTRA_CA_CERTS has not already been supplied.

## Tests

```sh
python3 -B -m unittest discover -s .setup/tests
```

Tests live with the setup code and use temporary Git repositories and homes.
They cover source edits, repeated deployment, conflicts, platform overrides,
repository aliases and migration of old directory links.
Application checks cover shared Vim installation, retained CoC choices, direct
native rc loading, prerequisite failures, failure propagation and unchanged reruns.

## Alternatives Considered

* Keeping GNU Stow on Linux and separate PowerShell link handling preserves two
  implementations with different conflict and rerun behavior.
* A maintained source/destination manifest duplicates information already
  represented by directories and becomes another list to update.
* Putting the deployer in `scripts` would prevent this checkout from installing
  itself when that separate repository is absent.
* Root wrappers and separate deployment CLIs add entry points without owning
  behavior. A runnable Python directory provides one command without them.
* Separate shell and PowerShell app installers duplicate decisions such as
  plugin selection and update policy. Python owns that orchestration; native
  application languages remain where their APIs require them.
* A tmux renderer and discovered Vim path files duplicate native configuration
  handling and discard valid preferences. Direct source files and Vim's own
  runtime discovery keep that behavior with the application.

The repository-local Python deployer provides one implementation and a small
placement convention without introducing another configuration manager.
