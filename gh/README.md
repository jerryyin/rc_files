# GitHub CLI accounts

Linux setup installs a small `~/.local/bin/gh` launcher ahead of the system CLI. For repository commands it reads the explicit `--repo`/`-R`, `GH_REPO`, repository API path, the checkout's explicit `gh repo set-default` choice, or its origin. Choosing the private fork with `gh repo set-default owner/repo` therefore preserves both repository and account selection when origin points to upstream. Without either default or origin, a single named remote such as MediaCrawler's `private` is supported; multiple alternatives are not guessed. When the github.com repository owner is also a saved login, it uses that login's token for this process only. Thus `gh run list` inside a personal repository uses its owner's login even while the globally active account is the work login. A missing token stops the call; it never silently retries under another identity. Explicit `GH_TOKEN` or `GITHUB_TOKEN` remains authoritative.

Authentication/configuration commands pass through to the real CLI. Organization-owned repositories and non-GitHub hosts retain the CLI's normal selection because an organization name cannot establish the intended user. Use an explicitly scoped token for those when the default account is unsuitable. Native Windows does not install this Linux launcher; agents must check identity and select a per-process credential there. No token or account cache is added to this checkout, and no global account switch occurs.

Normal setup deploys the launcher with `python3 .setup --config-only --package gh`. Credential setup remains separate: `python3 .setup credentials --package gh`. The latter preserves local account state unless explicitly reseeded with `--update`.

## Alternatives Considered

Changing the global default to the personal account would make work calls vulnerable to the opposite mistake and conflict with concurrent sessions. A reminder alone cannot correct an ordinary `gh run list`. The launcher handles owner-matched repositories mechanically while leaving ambiguous organization identities explicit. It does not probe multiple accounts until one works or alter repository remotes.
