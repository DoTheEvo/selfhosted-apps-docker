$REPOSITORY_PATH = 'C:\Backup'
$BACKUP_THIS = 'C:\Users'
$KOPIA_PASSWORD='aaa'

kopia policy set $BACKUP_THIS --before-folder-action "powershell -WindowStyle Hidden C:\win_vss_before.ps1"
kopia policy set $BACKUP_THIS --after-folder-action  "powershell -WindowStyle Hidden C:\win_vss_after.ps1"

kopia repository connect filesystem --path $REPOSITORY_PATH --password $KOPIA_PASSWORD
kopia snapshot create $BACKUP_THIS
kopia repository disconnect

