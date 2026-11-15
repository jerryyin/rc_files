# Workspace layout

Applies when: Cloning a repository, creating a worktree, choosing where a campaign, job or experiment writes, or naming a checkout path in a configuration (a campaign's lock or `campaign.toml`, a setup script, a skill) on a development machine or container.

Repositories sit at the top of the home directory, one level deep, and work happens inside the repository it belongs to:

- `/root/<repo>/` is the one primary clone of each repository (`tokenspeed`, `triton`, `triton-investigations`, `scripts`, `amd-tracking`, ...). Add a fork as a remote of that clone rather than cloning it again.
- `/root/<repo>-<topic>/` is a worktree of that clone for one branch or task (`git -C /root/<repo> worktree add /root/<repo>-<topic> ...`), beside its clone, never inside another directory.
- No project directory gathers several repositories. Work that spans repositories lives in each repository or worktree it touches; its notes, scripts and patches go in the one they concern.
- Run output stays outside repositories: `~/.local/state/<tool>/` for run state and logs, a campaign's `/root/campaigns/<campaign>/cache/` for its models, data and environments. A campaign directory holds no repository clones.

A configuration that names a checkout path names one of these. When a checkout moves, update the configurations that run from it; finished records keep the paths they cite.
