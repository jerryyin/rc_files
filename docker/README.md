# Docker configuration

The public template contains no registry credential. After making the vault available, run `python3 ~/rc_files/.setup credentials --package docker`. The hook reads `docker_mkmhub_auth.txt` as base64 `username:password` and updates only the managed registry, preserving other settings. `--vault`, `DOCKER_AUTH_FILE`, `DOCKER_CONFIG` and `DOCKER_REGISTRY` can select other locations or a registry.

When Docker uses a credential helper, the hook checks the helper first and sends a changed password to `docker login` through stdin. Missing tools skip authentication without writing a plaintext fallback; helper failures stop the hook without printing secret diagnostics. Credential setup installs no Docker components.
