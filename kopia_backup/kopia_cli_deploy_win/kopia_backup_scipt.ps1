# v0.2
# Before using this script, create a repo, note the setting of a password
# kopia repo create filesystem --path C:\kopia_repo --password aaa

# for backblaza b2
# kopia repository create b2 --bucket=rakanishu --key-id=001496285081a7e0000000003 --key=K0016L8FAMRp/F+6ckbXIYpP0UgTky0 --password aaa

# useful commands:
# - kopia repo status
# - kopia repo connect filesystem --path C:\kopia_repo -p aaa
# - kopia snap list --all
# - kopia mount all K:

# mounting might need be executed as non-admin user, weird windows thing
# if one does not see the drive:
# - 'net use' shows path that can be pasted to explorer or browser
#   \\127.0.0.1@51295\DavWWWRoot

# logs location is set C:\Kopia\Kopia_Logs for every command
# if it was not manually set then it would be
# C:\Windows\System32\config\systemprofile\AppData


# to backup multiple targets/paths:
# - [array]$BACKUP_THIS = 'C:\Test','C:\users','C:\blabla'

$REPOSITORY_PATH = 'C:\kopia_repo'
$KOPIA_PASSWORD = 'aaa'
[array]$BACKUP_THIS = 'C:\test'
$LOG_PATH = 'C:\Kopia\Kopia_Logs'
$USE_SHADOW_COPY = $false

# ----------------------------------------------------------------------------

$Env:KOPIA_LOG_DIR = $LOG_PATH

kopia repository connect filesystem --path $REPOSITORY_PATH --password $KOPIA_PASSWORD
# kopia repository connect b2 --bucket=kopia-repo-rakanishu --key-id=001496285081a7e0000000003 --key=K0016L8FAMRp/F+6ckbXIYpP0UgTky0

kopia policy set --global --compression=zstd-fastest --keep-annual=0 --keep-monthly=12 --keep-weekly=0 --keep-daily=14 --keep-hourly=0 --keep-latest=3

if ($USE_SHADOW_COPY) {
  kopia policy set --global --enable-volume-shadow-copy=when-available
}

foreach ($path in $BACKUP_THIS) {
  kopia snapshot create $path --file-log-level=info
}

kopia repository disconnect
