# BorgBackup in docker

###### guide by example

![logo](https://i.imgur.com/dR50bkP.png)

# purpose

Backups.

* [Official site](https://www.borgbackup.org/)
* [Github](https://github.com/borgbackup/borg)

# files and directory structure

```
/home/
└── ~/
    ├── borg/
    │    ├── docker_backup/
    │    ├── borg_backup.sh
    │    └── borg_backup.log
    │
    └── docker/
        ├── container-setup #1
        ├── container-setup #2
        ├── ...
```

# The setup

BorgBackup is installed directly on the host system.</br>
A script is created that backs up the entire docker directory locally.</br>
Cronjob is executing this script daily.

#### • Install BorgBackup

#### • Create a new borg repo
  
`mkdir ~/borg`</br>
`borg init --encryption=none ~/borg/docker_backup`

#### • The script

`borg_backup.sh`
```bash
#!/bin/bash

# INITIALIZE THE REPO WITH THE COMMAND:
#   borg init --encryption=none ~/borg/my_backup
# THEN RUN THIS SCRIPT

# -----------------------------------------------

BACKUP_THIS='/home/bastard/docker /etc'
REPOSITORY='/home/bastard/borg/docker_backup'
LOGFILE='/home/bastard/borg/borg_backup.log'

# -----------------------------------------------

NOW=$(date +"%Y-%m-%d | %H:%M | ")
echo "$NOW Starting Backup and Prune" >> $LOGFILE

# CREATES NEW ARCHIVE IN PRESET REPOSITORY

borg create                                     \
    $REPOSITORY::'{now:%s}'                     \
    $BACKUP_THIS                                \
                                                \
    --compression zstd                          \
    --one-file-system                           \
    --exclude-caches                            \
    --exclude-if-present '.nobackup'            \
    --exclude '/home/*/Downloads/'              \

# DELETES ARCHIVES NOT FITTING KEEP-RULES

borg prune -v --list $REPOSITORY                \
    --keep-daily=7                              \
    --keep-weekly=4                             \
    --keep-monthly=6                            \
    --keep-yearly=0                             \

echo "$NOW Done" >> $LOGFILE
echo '------------------------------' >> $LOGFILE

# --- USEFULL SHIT ---

# setup above ignores directories containing '.nobackup' file
# make '.nobackup' imutable using chattr to prevent accidental removal
#   touch .nobackup
#   chattr +i .nobackup

# in the repo folder, to list available backups:
#   borg list .
# to mount one of them:
#   borg mount .::1584472836 ~/temp
# to umount:
#   borg umount ~/temp
# to delete single backup in a repo:
#   borg delete .::1584472836
```

the script must be **executabe** - `chmod +x borg_backup.sh`

#### • Automatic execution

cron job, every day at 3:00</br>
`crontab -e`</br>
`0 3 * * * /home/bastard/borg/borg_backup.sh`

# Remote backup

Backing up borg repo to a network share or cloud using rclone

*To be continued*
