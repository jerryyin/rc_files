# WSL appends every Windows PATH folder, and each one costs a slow /mnt lookup whenever a
# command is hashed or missing. Keep only the folders of Windows tools used from Linux:
# clip.exe (tmux-yank), cmd.exe, wsl.exe, explorer.exe, powershell.exe, pwsh.exe, code and cursor.
[[ -n ${WSL_DISTRO_NAME:-} ]] || return 0
() {
  setopt local_options extended_glob
  local -a windows=(${${(M)path:#/mnt/[a-z]/*}%/})
  path=(${path:#/mnt/[a-z]/*}
        ${(M)windows:#(#i)/mnt/[a-z]/(windows(|/system32(|/windowspowershell/v1.0))|*/(powershell/7|cursor/resources/app/bin|microsoft\ vs\ code/bin))})
}
typeset -U path
