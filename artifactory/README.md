# Artifactory credentials

This package installs no software. On Linux, explicit credential setup reads `atlartifactory_token.txt` from the supplied vault and maintains its marked block in `~/.netrc`, preserving other hosts. Missing tokens preserve the file. `ARTIFACTORY_KEY_FILE`, `NETRC_HOST` and `NETRC_LOGIN` override the source, host and login. Normal setup never reads the token.

With `--persistent-root`, the credential phase can share the private netrc file with trusted container storage. Differing local files are preserved; `--save` explicitly saves local state. Windows netrc and native sign-in are left local.
