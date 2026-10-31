# Personal configuration

Tracked application settings, personal agent guidance and editor preferences for Linux and Windows. This checkout includes its own Python setup; a separate `scripts` checkout is not required.

- [Setup and placement conventions](.setup/README.md)
- [Vim configuration and daily use](vim/README.md)
- [Shared agent instructions, rules and skills](agents/README.md)

Installed links keep configuration edits attached to their Git source. Plugin downloads, caches, credentials and application state stay local. Declared application requirements are installed by this checkout. Machine provisioning, credentials and project workflows belong to the separate [scripts repository](https://github.com/jerryyin/scripts).

## Private credentials

Application credential hooks select exactly one private repository: `python3 .setup credentials --vault-scope homelab` reads `~/vault-homelab`; `--vault-scope work` reads `~/vault-work`. `--vault PATH` overrides the location, not its required `.vault-scope` marker. The old mixed `~/vault` is never a fallback. Work owns AMD GitHub, AMD Claude gateway, AtlArtifactory and MKMHub; home owns personal GitHub and home services. GitHub activation renders one selected account on Linux. Native host accounts already stored in Windows remain available.

Scripts owns cloning and container mounts; see `jerryyin/scripts` → `setup/credentials.md`. Use separate homes and persistent directories for work and homelab containers. Hosts may retain both checkouts, but containers must not receive a whole-host-home bind or its SSH agent.
