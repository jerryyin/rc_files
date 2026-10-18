# Optional Linux application setup

Run `bash install.sh` from the checkout root to deploy configuration and prepare
the installed applications. The root command discovers the shell installers in
this directory; each owns one application's setup:

* `vim.sh`: vim-plug plugins and CoC extensions.
* `tmux.sh`: TPM and tmux plugins.
* `zsh.sh`: default shell selection and initial Zinit plugin downloads.

These installers can also be run individually after configuration deployment.
They use the installed configuration paths and do not require the `scripts`
repository. System package installation remains in that separate repository.
The deployment engine and its tests are documented in
[`.deploy/README.md`](../.deploy/README.md).
