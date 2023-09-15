# Before using this script, create a repo, note the setting of a password
# kopia repo create filesystem --path C:\kopia_repo --password aaa --file-log-level=info --log-dir=C:\Kopia\Kopia_Logs

# for backblaza b2
# kopia repository create b2 --bucket=rakanishu --key-id=001496285081a7e0000000003 --key=K0016L8FAMRp/F+6ckbXIYpP0UgTky0 --password aaa

# useful commands:
# - kopia repo connect filesystem --path C:\kopia_repo -p aaa
# - kopia snap list -all
# - kopia mount all K:
# mounting should be used as non-admin user, weird windows thing
# or one does not see the drive, in that case:
# - net use - shows path that can be pasted to explorer or browser
#   \\127.0.0.1@51295\DavWWWRoot

# logs location is set C:\Kopia\Kopia_Logs for every command
# if it was not manually set then it would be
# C:\Windows\System32\config\systemprofile\AppData

#
# to backup multiple targets/paths:
# - [array]$BACKUP_THIS = 'C:\Test','C:\users','C:\blabla'

$REPOSITORY_PATH = 'C:\kopia_repo'
$KOPIA_PASSWORD = 'aaa'
[array]$BACKUP_THIS = 'C:\Test'
$USE_SHADOW_COPY = $false

# ----------------------------------------------------------------------------

kopia repository connect filesystem --path $REPOSITORY_PATH --password $KOPIA_PASSWORD --file-log-level=info --log-dir=C:\Kopia\Kopia_Logs
# kopia repository connect b2 --bucket=kopia-repo-rakanishu --key-id=001496285081a7e0000000003 --key=K0016L8FAMRp/F+6ckbXIYpP0UgTky0

kopia policy set --global --compression=zstd-fastest --keep-annual=0 --keep-monthly=12 --keep-weekly=8 --keep-daily=14 --keep-hourly=0 --keep-latest=3 --file-log-level=info --log-dir=C:\Kopia\Kopia_Logs

foreach ($path in $BACKUP_THIS) {
  if ($USE_SHADOW_COPY) {
    kopia policy set $BACKUP_THIS --before-folder-action "powershell -WindowStyle Hidden C:\Kopia\win_vss_before.ps1" --file-log-level=info --log-dir=C:\Kopia\Kopia_Logs
    kopia policy set $BACKUP_THIS --after-folder-action  "powershell -WindowStyle Hidden C:\Kopia\win_vss_after.ps1" --file-log-level=info --log-dir=C:\Kopia\Kopia_Logs
  }
  kopia snapshot create $path --file-log-level=info --log-dir=C:\Kopia\Kopia_Logs
}

kopia repository disconnect --file-log-level=info --log-dir=C:\Kopia\Kopia_Logs
