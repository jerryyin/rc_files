# Shared AGENTS.md and skills migration plan

## Goal and scope

Use one Git-owned collection of personal instructions, rules, and skills across Claude Code, Codex, and Cursor on Windows and Ubuntu. Author shared instructions in `AGENTS.md`, reuse the existing Python deployer, and retain only the links required by the tools' discovery locations. Adding personal content must not require updating a manifest or a separate inventory.

The migration is implemented and applied to native Windows and Ubuntu/WSL. It includes the agent configuration package in `rc_files`, its setup checks, and removal of the obsolete Cursor rule installation in `scripts`. Application installers and native permission settings retain their existing owners. Interactive model verification is deferred at the user's request; Claude checks use a local stub.

## Compatibility checked on 2026-10-18

- **Codex:** reads project `AGENTS.md` and user-wide `~/.codex/AGENTS.md`. A project file does not replace the user-wide entrypoint. See the [official OpenAI documentation](https://learn.chatgpt.com/docs/agent-configuration/agents-md).
- **Claude Code:** supports project `AGENTS.md` starting with v2.1.277. Its default can prefer an existing project `CLAUDE.md`; the documented setting can load both. Personal instructions still use `~/.claude/CLAUDE.md`. Both local installations were updated through npm to `2.1.303` for the loading checks; the installer continues to select the latest release. See [Claude's AGENTS.md support and user instruction locations](https://code.claude.com/docs/en/memory#agentsmd).
- **Cursor:** reads project `AGENTS.md`; its documented global User Rules are account settings. Project support does not establish that a home-directory `AGENTS.md` applies across unrelated repositories. See [Cursor's instruction locations](https://cursor.com/help/customization/rules).
- **Skills:** `AGENTS.md` does not replace `SKILL.md` discovery. Codex and Cursor support `~/.agents/skills`; Claude documents `~/.claude/skills`. Keep those two installed roots pointing at the same personal skill sources. See [Codex skills](https://learn.chatgpt.com/docs/build-skills), [Cursor skills](https://cursor.com/docs/skills), and [Claude skills](https://code.claude.com/docs/en/skills).

**Decision:** use uppercase `AGENTS.md` as the sole authored shared instruction file. Use native project support wherever available. Keep the two global instruction aliases that the products still require, plus one Cursor account entrypoint. A universal filename does not give all products the same user-wide discovery location.

## Source layout

```text
rc_files/
  agents/
    .agents/
      AGENTS.md
      rules/
        python-style.md
        ...
      skills.links/
        root-cause-debug/
          SKILL.md
        ...
    .codex/
      AGENTS.md -> ../.agents/AGENTS.md
    .claude/
      CLAUDE.md -> ../.agents/AGENTS.md
      skills.links -> ../.agents/skills.links
```

The arrows represent tracked repository aliases, not copied content. The existing deployer resolves aliases and installs direct links to their final source. Its existing `.links` convention discovers each tracked personal skill automatically. Tool-specific settings such as Claude's `settings.json` remain in their application packages.

`AGENTS.md` contains shared personal preferences and the common instructions for selecting relevant topic rules and skills. Short, always-needed guidance belongs directly in that file. Conditional guidance belongs in `rules/`; multi-step procedures and large templates belong in skills and their reference files.

## Installed entrypoints and link budget

### Shared instructions

- `~/.agents/AGENTS.md` links to `rc_files/agents/.agents/AGENTS.md`. This gives all tools a stable, neutral path independent of the checkout's location.
- `~/.codex/AGENTS.md` links directly to that same tracked source.
- `~/.claude/CLAUDE.md` links directly to that same tracked source. This is a global discovery alias and contains no separately authored Claude preferences.
- Cursor has one global User Rule directing it to read `~/.agents/AGENTS.md`. That rule holds only the loading instruction; the policy stays in the shared file.

This is one normal deployment link and two compatibility links for shared instructions, regardless of the number of projects. The Cursor account entrypoint may require an initial UI step; do not rely on editing an undocumented local database or on a home-directory file being discovered as a project rule.

Suggested Cursor User Rule:

```text
At the start of a session, read ~/.agents/AGENTS.md and follow its personal instructions alongside the project's instructions. If the file cannot be read, report its path and the access problem.
```

This is an instruction for the agent to read a file, not a native file import. Confirm the actual read in a fresh session before relying on it. Existing project instructions keep their native scope and the product's instruction precedence.

### Personal skills

Install each managed skill directory into `~/.agents/skills/<name>` and `~/.claude/skills/<name>`, linking both to the same tracked directory. Add no third set of Cursor skill links: it already searches the shared root.

Retain per-skill directory links instead of linking whole application skill roots. The Windows shared root currently also contains an installed collection outside the personal Git-owned skills. Whole-root links could mix application writes into `rc_files` or expose tool-specific content to another tool. Directory links for individual personal skills preserve atomic saves and new helper files within those skills.

### Project instructions

Author project-owned guidance as `AGENTS.md` inside the project, using nested files when directory scope is needed. Use current native support in Codex, Cursor, and updated Claude Code. Do not install personal preferences into every project or create per-project `.mdc` mirrors. Preserve existing project `CLAUDE.md` files; choose a documented Claude setting or an explicit import only when that project's existing configuration requires it.

## Shared rule selection

Keep personal topic rules under `~/.agents/rules`, outside any tool's automatic rule directory. Each rule states its own applicability. The common `AGENTS.md` instructs every agent to discover and read relevant rules by their names and applicability, without a second rule-name list.

This deliberately uses the same written selection instructions in all three tools. It does not claim that every tool implements the same native glob loader or that Markdown is an enforced permission mechanism. Do not maintain duplicate `globs` and `paths` fields or generate `.mdc` translations for the shared collection.

Separate portable workflow instructions from capability-specific steps. For example, campaign supervision can describe its scheduling requirement once, then select an available scheduling tool. A workflow needing Linux commands names the WSL, container, or remote execution host. An unavailable capability is reported explicitly. The shared instructions do not need to be rewritten in PowerShell just because the agent is launched on Windows.

## Migration sequence

### 1. Reconcile authored content

Inspect the personal skill and rule roots in both actual homes. Compare unmanaged content with the tracked sources and establish its owner before moving it. In particular, reconcile Ubuntu's divergent `~/.cursor/skills/talk-gist` copy. Preserve wanted edits and back up displaced files before relinking. Leave credentials, runtime state, application-managed skills, and unrelated changes under their existing ownership.

Completion: every personal item selected for migration has one agreed source; differing local edits have been reviewed rather than discarded.

### 2. Consolidate the shared AGENTS.md

Move the shared preferences from `claude/.claude/CLAUDE.md` to the proposed neutral source. Resolve conflicting automatic-commit and standing-push language in the campaign and review instructions against the current Git approval requirement. Move long task procedures and templates out of ambient rules, preserving references and intended behavior. Put the common authoring and rule-selection conventions in `AGENTS.md`.

Completion: shared instructions are authored once; no old rule or skill grants conflicting authority.

### 3. Move sources and update links together

Move personal skills and topical rules into the neutral package, update their references and repository aliases, and deploy using `rc_files/.setup`. Adjust only the relevant ignore exceptions so authored additions remain visible to Git; preserve the existing exclusion of generated files. Keep placement discovery generic and retain directory-link behavior. Stage new ignored configuration explicitly when necessary.

Preserve and retire obsolete links owned by this checkout, including the former personal `.claude/rules` files, so both loaders cannot remain active after the move. Do not replace unrelated local files or rewrite project instructions. Preserve the existing staged work and local SSH edit in the Ubuntu checkout.

Completion: installed personal content resolves to the new source on both systems, with no active copies or retired source links left behind.

### 4. Establish native instruction loading

Update Claude Code through its existing installation path to the current supported release before checking project `AGENTS.md`; the version above is a compatibility observation, not an installation pin. Verify the existing global aliases and configure the single Cursor account entrypoint. Check actual instruction loading from a project outside the home directory and from a Git worktree.

Completion: each product demonstrably reads the shared personal file and its own project instructions; a native entrypoint or compatibility step is retained only where needed.

### 5. Retire the old Cursor adapter

After the replacement is verified, remove `scripts/docker/env/cursor.sh`'s personal-rule workspace scan, its call from `min.sh`, and tests or documentation that describe the old mirrors. Preserve any unrelated installer responsibilities. Keep agent configuration ownership and its checks in `rc_files`; `scripts` installs applications and calls the shared setup.

Completion: new projects do not need a rules refresh, and no Bash-only rule linker remains in the setup path.

### 6. Verify and review the completed migration

Run focused placement and ownership checks, then inspect actual instruction and skill discovery in fresh Windows and Ubuntu sessions. Verify the required application installations and authentication before claiming coverage of a tool/host combination; native Windows Claude was absent at the audit. Do not report a filesystem check as proof that an agent loaded the content.

Completion: the acceptance criteria below pass for the tested combinations, with missing access or unsupported environments named explicitly. Stage the implementation for review; commit and push only when requested in that user turn.

## Acceptance criteria

- Every tool reads the same shared personal `AGENTS.md`, and project-owned guidance remains available without copying the personal file into the project.
- All managed personal skills appear in each tool's discovery with the expected source paths and no competing unmanaged versions.
- A Python task reads the Python rule; an unrelated task does not load campaign instructions. Capture actual file reads or context evidence, not the model's unsupported assertion that the setup works.
- Editing an installed personal skill and adding a helper within it changes the Git source. New personal rules and skills are authored in `rc_files` before deployment, so creating a sibling in an application directory cannot silently become the authoring convention.
- A fresh clone at a different location deploys without a source-path manifest. A second deployment leaves correct links and file timestamps unchanged and creates no redundant backups.
- Existing project `AGENTS.md`, project `CLAUDE.md`, local edits, generated-file exclusions, and tool-managed skill collections survive the migration.
- No per-project personal rule links, generated instruction copies, or persistent installation inventory are introduced. The necessary skill directory links remain derived from tracked placement.
- Remote use is checked in the actual remote home after deploying the collection there. Local home links and account-synced pointers do not establish cloud availability. Cloud and Cowork are separate acceptance targets, not implied by local success.

## Alternatives Considered

- **One home-directory AGENTS.md and no entrypoints:** smallest apparent link count, but project-file discovery does not provide a common global entrypoint across all three tools. Reject as the personal installation design.
- **Project AGENTS.md everywhere with generated per-project links:** uses native filenames but duplicates installation work across unrelated repositories and risks conflicts with their own guidance. Keep native project files for project-owned content only.
- **Separate native rule trees or generated translations:** requires ongoing metadata conversion and makes file ownership harder to review. Reject for the shared collection.
- **Shared AGENTS.md with minimal global entrypoints:** one authored policy file, no per-project personal mirrors, and only the compatibility needed by documented user-wide discovery. Choose this approach.

## Implementation and local acceptance

The change was prepared against native Windows `rc_files/master` at `6b8c52a` and `scripts/main` at `ecb78ef`. Both actual homes now use the neutral collection: 11 conditional rules and 16 personal skills, with the former twelfth rule moved into the campaign skill's reference directory. The original rule and skill bodies are preserved except for the agreed scope, ownership, host-capability and Git-authority corrections.

- Windows passes all 81 discovered configuration link checks; Ubuntu passes all 93 after retiring the seven inherited workspace files. Former source-owned Claude rule links are backed up and retired. No old personal project rule links were found in the locations used by the removed Cursor installer.
- The focused deployment and agent-collection tests pass on both platforms, including relocation, shared aliases, skill ownership, generated-file exclusions, bounded retired-link cleanup and unchanged reruns. Windows also passes 78 environment assertions and 49 configuration ownership checks.
- Codex's local `skills/list` reports all 16 managed personal skills enabled, without discovery errors, on both platforms. Other installed skills remain application-owned.
- Claude's actual CLI on each platform sends the shared preferences, an unrelated project's native `AGENTS.md`, and all 16 personal skill names to a loopback stub. No real model response is used. The campaign rule body is absent from startup context. This checks loading, not whether a model chooses the correct conditional rule during a real task.
- Cursor's account User Rule was added through its Settings UI and read back there. Its only policy is the shared-file loading pointer shown above. The Skills UI lists the 16 personal skills. A fresh model session still needs to demonstrate the file read and conditional selection.
- Ubuntu's divergent Cursor `talk-gist` copy was backed up and retired; its useful extra paragraph is in the shared source. Its unrelated staged work and local SSH configuration are preserved.
- The inherited `cursor/.cursor/workspace` package was removed after confirming that its task records and directory map were placeholders and its helper scripts had no external references. Its seven installed links are retired with the cleanup; personal guidance stays in the neutral agent package.
- Fresh scratch homes passed full setup twice on both platforms. Windows passed 128 bootstrap assertions with 109 monitored files unchanged; Ubuntu kept all 134 monitored files unchanged. Neither rerun created configuration backups. Each platform passed 50 setup tests; Windows skipped the Linux shell case. Additional checks covered native Vim, clangd, LeaderF, pane navigation, credentials using fake data, and fresh Zsh startup. The scratch tests found and fixed test-fixture alias metadata loss and a Linux tmux plugin-loader quoting error for home paths containing spaces.
- Native Windows Codex resolves its user skill root from the actual Windows account. Its scratch discovery check selects the deployed scratch directory as a project root and verifies that all 16 returned skill sources resolve into that clone; the real account's separate entries are recorded separately. A scratch folder does not simulate a newly created Windows account. Machine package installation, font registration, WSL installation, GUI operation and interactive authentication require separate machine-level acceptance.

Acceptance records and displaced links are local runtime artifacts under `%LOCALAPPDATA%/PersonalDevenv/acceptance/agents-refactor-*` and `scratch-verification-*` on Windows, `~/.local/state/devenv-acceptance/agents-refactor-*` on Ubuntu, and the Ubuntu scratch run's `/tmp/agents-scratch-*` directory. These records are evidence, not a deployment inventory or configuration dependency.

Interactive checks remain for the user: start fresh Claude, Codex and Cursor tasks, confirm selection of the Python rule for Python work and exclusion of campaign guidance from unrelated work, and check any intended remote/cloud execution home separately. Account pointer synchronization does not deploy the referenced file to a remote host. Projects with existing `CLAUDE.md` keep Claude's documented preference unless that project's owner selects the documented read-both option.
