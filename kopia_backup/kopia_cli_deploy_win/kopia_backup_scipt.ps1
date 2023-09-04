# Before using this script, initiate the repo
# kopia repo create filesystem --path C:\kopia_repo --password aaa

# useful commands
# kopia repo connect filesystem --path C:\kopia_repo -p aaa
# kopia snap list -all
# kopia mount all K:
#   mounting should be used as non-admin user, weird windows thing
#   or one does not see the drive, in that case
#   net use - shows path that can be pasted to explorer or browser
#   \\127.0.0.1@51295\DavWWWRoot

# logs location when run as task scheduler
# C:\Windows\System32\config\systemprofile\AppData

# config
# example of $BACKUP_THIS with multiple paths
# [array]$BACKUP_THIS = 'C:\Test','C:\Test2','C:\Test3'

$REPOSITORY_PATH = 'C:\kopia_repo'
$KOPIA_PASSWORD='aaa'
[array]$BACKUP_THIS = 'C:\Test'
$USE_SHADOW_COPY = $false

# ----------------------------------------------------------------------------

kopia repository connect filesystem --path $REPOSITORY_PATH --password $KOPIA_PASSWORD --enable-actions

foreach ($path in $BACKUP_THIS) {
  if ($USE_SHADOW_COPY) {
    kopia policy set $BACKUP_THIS --before-folder-action "powershell -WindowStyle Hidden C:\Kopia\win_vss_before.ps1"
    kopia policy set $BACKUP_THIS --after-folder-action  "powershell -WindowStyle Hidden C:\Kopia\win_vss_after.ps1"
  }
  kopia snapshot create $path --file-log-level=info
}

kopia repository disconnect
