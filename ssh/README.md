# SSH

The shared `.ssh/config` links into the home directory on Linux and Windows. It contains public GitHub routing and general preferences. Host inventories belong in the private vault's `ssh/config`, read through the `~/.ssh/private.conf` link. Edits through either installed configuration link reach its Git-owned source. A missing vault is supported, and public setup never reads private contents.

```sh
python3 .setup --package ssh
python3 .setup credentials --package ssh
python3 .setup credentials --package ssh --vault /path/to/vault
python3 .setup credentials --package ssh --source /trusted/backup/.ssh
python3 .setup credentials --package ssh --persistent-root /mounted/home
```

On Windows, replace `python3` with `py -3`. Normal setup installs the Linux client or prepares Windows' OpenSSH Client, agent service and trusted configuration links; redirected test homes never change services. Windows bootstrap groups preparation into its existing administrator phase. The private configuration link may initially be dangling: creating it does not read the vault, and SSH works before that vault is available. For a custom Windows vault location, bootstrap passes its selected `-VaultPath`; standalone setup can use `RC_CREDENTIALS_VAULT`. Linux activation reuses an available agent rather than starting a child process whose environment would disappear when setup exits.

The credential hook protects local keys, imports only missing `id_*` key pairs from an explicit source or persistent root, and loads usable keys into an existing agent. Existing keys are never overwritten. Private key material stays outside Git. Linked configuration is preserved; differing private configuration needs reconciliation before activation. Encrypted keys that need unlocking are left for an explicit `ssh-add`, so unattended activation cannot stop at a passphrase prompt. A missing agent leaves keys usable directly. Credential activation never installs software or requests administrator access.

Linux session startup invokes the SSH hook inside first-time bootstrap, before accessing the private vault. The private configuration link can point to a not-yet-available vault, so one SSH invocation prepares both keys and configuration. Routine application credential refresh excludes SSH. To import newly added keys later, run the SSH credential command explicitly or run `scripts/setup/linux/credentials/activate.sh --force`. Edits to the linked host inventory are visible immediately without reinitialization.

`AddKeysToAgent yes` lets ordinary SSH connections add a key to the local agent. `ForwardAgent no` is the default; opt in for individual trusted hosts in the private inventory when a second-hop connection needs your local agent. GitHub uses `ssh.github.com:443` and `accept-new`, preserving verification of previously recorded host keys. Keys, `known_hosts`, and incoming-access files remain local; setup does not replace the whole `.ssh` directory. Workflow-specific remote key transfers and pod connection options stay with their launchers in `scripts`.

## Alternatives Considered

Keeping the entire SSH config public would publish internal host details. Keeping it entirely untracked would lose reusable preferences. A small public entry point and one private included file preserve version control without a generated configuration or a second inventory format. Separate Windows and Linux host lists would drift; native `Include` and home-relative paths let both use the same files. Key handling belongs in the SSH package's credential hook so bootstrap and standalone installation share one implementation.

## Checks

```sh
python3 -B -m unittest discover -s .setup/tests -p test_credentials.py -k SshTests
python3 -B -m unittest discover -s ssh/.setup/tests -p test_keys.py
```

Windows agent readiness is checked without changing services by `powershell.exe -NoProfile -File ssh/.setup/tests/Test-Windows.ps1`. From an administrator PowerShell, `ssh/.setup/tests/Test-Deployment.ps1` exercises a fresh temporary home before and after vault availability, using fake service operations and no real keys. Use `ssh -G HOST` to inspect the effective settings without connecting.
