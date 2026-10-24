# Configuration setup

This directory provides one Python command for installing configured applications, linking this checkout's configuration and preparing plugins on Linux and Windows. Git and Python 3.10+ are required. Windows also needs Developer Mode or permission to create symbolic links.

## Start here

Run from the repository root; an absolute path to `.setup` also works. On Windows, replace `python3` with `py -3`.

```sh
python3 .setup plan
python3 .setup --config-only
python3 .setup check
```

`plan` shows the discovered destinations. `--config-only` links configuration and migrates links from older layouts. `check` reports missing or detached links; it does not prove that an application loaded its settings.

Full setup installs missing native requirements through apt on Ubuntu/Debian or WinGet on Windows, then links configuration and prepares application plugins. Git and Python remain the initial prerequisites; Windows also requires WinGet and permission to create links.

```sh
python3 .setup
```

Each package owns its requirements, application commands and platform differences. The runner collects selected packages and their dependencies, installs missing requirements, deploys their configuration, then runs their setup entries in dependency order. Linux reuses existing usable tools. Windows requires machine-scoped installations, so an existing per-user command does not satisfy a shared requirement. WinGet and declared npm requirements share one administrator step; application settings and plugins run as the current user. Standalone setup does not require `scripts`. That repository owns WSL, machine policy, vault availability, interactive sign-in, everyday utilities and project workflows, and delegates configured application setup here.

Windows npm commands (Claude, Codex and the Codex ACP adapter) use `%ProgramFiles%\npm` and the machine PATH; personal npm settings are unchanged. PowerShell uses its machine MSI installer. Windows Terminal is provisioned for new accounts, rather than accepting current-user registration alone. The terminal package registers its font under `%WINDIR%\Fonts` and HKLM; standalone font setup requests elevation when needed. The Windows bootstrap in `scripts` includes fonts in its existing administrator phase. Existing user installations are not automatically uninstalled, and no profiles or credentials are copied to another account.

Once machine prerequisites and fonts are installed, another account can clone this repository and run `py -3 .setup --no-install` to apply its own configuration and plugins. Developer Mode must already permit configuration links. Each account performs its own credential setup; WSL distributions also remain per-account.

Packages without declared requirements or setup entries only deploy configuration. Keeping settings for applications such as Emacs or Kitty does not automatically request their installation.

## Placement conventions

Every non-hidden top-level directory is a package. Root files and hidden root directories, including `.setup`, are repository utilities and are not installed.

- A package mirrors its destination: `vim/.vimrc` installs as `~/.vimrc` on both platforms.
- `README.md` at a package root describes that package and is excluded from deployment, including at the root of a platform subtree. Markdown within configuration trees keeps its normal destination; agent instructions, rules and skills are installed content.
- A package's `.setup/` directory contains its installation code and is excluded from deployment. An optional tracked `.setup/__main__.py` is its setup entry, shared across platforms. An optional `.setup/credentials.py` runs only in the explicit credential phase. An optional `.setup/requirements.py` declares package dependencies and native requirements. Runtime and untracked files do not register setup entries.
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

`--package vim` includes its Node and clangd packages. `--no-install` requires existing tools and prevents system package and CLI installation; declared system requirements are checked before linking, and package entries check their additional tools. Plugin preparation still runs. A redirected `--home` never installs machine packages or changes the login shell or font registration. `--skip-setup PACKAGE` still links that package and checks its native requirements, while skipping its setup entry.

`prerequisites --json` reports missing declared requirements without changing files; `prerequisites --scope machine` installs only machine-scoped requirements. On Windows these include declared npm commands; `--update` refreshes those commands in the administrator phase. The Windows workstation bootstrap combines these requirements and the package-owned font installer with its machine changes under one elevation, then uses `--no-install` for user setup. Full Linux setup also prepares package-owned tools such as Node, the GitHub CLI and npm CLIs.

Each package decides which platforms it supports and what `--update` refreshes. `--config-only` skips every package setup entry. Application requirements, dependency choices and maintenance behavior belong with the package; see [Vim's guide](../vim/README.md) for an example.

The runner starts each tracked entry with its own Python interpreter and the entry's directory as the working directory, stopping on the first failed process. Entries locate their source files relative to `__file__` and use the inherited environment: `HOME` (also `USERPROFILE` on Windows), redirected XDG/application directories for another home, `RC_SETUP=1`, `RC_SETUP_UPDATE=0` or `1`, and `RC_SETUP_REDIRECTED=0` or `1`, and `RC_SETUP_INSTALL=0` or `1`. The shared `.setup` helpers are on `PYTHONPATH`. `RC_SETUP_REDIRECTED` lets an entry avoid touching a live account session when testing another home. Public Git downloads are noninteractive and ignore the account's global Git configuration. Entries own additional environment requirements, such as npm's certificate bundle. The shared runner has no application registry, application dependency list or application-specific options. Requirements files import `Package` from `system`, declare `PACKAGES`, and optionally declare `DEPENDENCIES` using package directory names. `PLATFORM` is supplied by discovery. All requirements files must be free of installation side effects; only tracked files participate.

Applications read their linked configuration directly. Reload or restart the application after editing its settings. Packages may generate private credential-bearing settings from tracked templates; those files remain local and their package guide describes how they are refreshed.

### Alternatives considered

Keeping application calls in the central command would require changing it for every new application. A manifest describing installation commands would add another format alongside Python and native plugin declarations. Package-owned Python requirements keep native package choices beside application setup. Shared helpers implement package manager operations and executable discovery. Keeping dependencies in `scripts` would make standalone setup incomplete; a central application inventory would make the generic runner depend on every application. Package dependencies are discovered from tracked files without a separate registration list.

## Credentials at session startup

Normal setup never invokes credential hooks or reads vault files, even when a vault is present. Image builds can install every application and its public settings without access to secrets. After a host or container makes private storage available, run:

```sh
python3 ~/rc_files/.setup credentials
python3 ~/rc_files/.setup credentials --vault /path/to/vault
python3 ~/rc_files/.setup credentials --package claude
python3 ~/rc_files/.setup credentials --persistent-root /mounted/home
```

The credential command discovers tracked `<package>/.setup/credentials.py` entries, without evaluating requirements, installing dependencies, linking ordinary configuration or running application setup. It uses the same home and package selection conventions. `--vault` defaults to the selected home's `vault` directory; it never clones that directory. Missing entries preserve existing credentials. Invalid input stops the affected hook without printing secret values. Packages own secret names, destination formats and platform behavior; shared private file helpers reject Git destinations and use restricted, atomic file writes.

On Linux, packages can share their login files with explicitly supplied private storage. Differing local logins are preserved. To save a new login or refreshed file after an application replaces its installed link, use:

```sh
python3 ~/rc_files/.setup credentials --persistent-root /mounted/home --save
```

Saving runs only persistence hooks; it does not render vault templates. On Windows, the gh hook stores the same vault tokens in the Windows credential store; Codex sign-in stays manual and Linux login files are not imported. See the application guides for credential refresh behavior. `scripts` locates or clones the vault at session startup and then invokes this command; the configuration repository remains usable without it.

Keeping vault rendering in `scripts` would duplicate application knowledge across the two repositories. Running it during ordinary setup would put credentials into image builds whenever a vault happened to be available. A separate command with package-owned hooks keeps secret access explicit without a central application inventory.

## Other destinations and checks

`plan`, `apply` and `check` accept repeated `--package NAME` selections. `--home PATH` selects another home; `--root NAME=PATH` redirects a destination root. A longer root key can redirect a subtree, such as an unpackaged Windows Terminal settings location. These are invocation arguments, not stored bookkeeping. Use `--help` for the full command interface.

`plan --json` and `check --json` expose discovered links for installers and readiness checks. Shared setup tests live in `tests/`; application tests live beside their package's setup. Tests use temporary repositories and homes. Run from the repository root with:

```sh
python3 -B -m unittest discover -s .setup/tests
python3 -B -m unittest discover -s vim/.setup/tests
python3 -B -m unittest discover -s tmux/.setup/tests
```
