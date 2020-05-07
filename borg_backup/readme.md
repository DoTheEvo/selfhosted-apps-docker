# BorgBackup in docker

###### guide by example

![logo](https://i.imgur.com/dR50bkP.png)

# Purpose & Overview

Backups.

* [Official site](https://www.borgbackup.org/)
* [Github](https://github.com/borgbackup/borg)

Borg is an open source deduplicating archiver with compression and encryption.</br>
Written in python with performance critical code implemented in C/Cython.

Highlight of borg is the deduplication, where files are cut in to variable size
chunks, and only new chunks are stored. 
This allows to keep snapshots from several days, weeks and months,
while not wasting disk space.

In this setup borg is installed directly on the host system.</br>
A script is created that backs up the entire docker directory and /etc locally.</br>
Cronjob is set to execute this script daily.

The repository is also pruned on each run of the script -
old archives are deleted while keeping the ones fitting the retention rules
in the script.</br>
One backup per day for last 7 days, last 4 weeks, last 6 months are kept.

# Files and directory structure

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

* `docker_backup/` - borg repository directory
* `borg_backup.sh` - the backup script that adds new archive in to the repository
* `borg_backup.log` - log file with the dates of backups

Only `borg_backup.sh` has to be provided.</br>
Repo directory is created by `borg init` command
and the log file is created on the first run.


# The setup

#### Install BorgBackup

Borg is likely in your linux repositories.

#### Create a new borg repo
  
`mkdir ~/borg`</br>
`borg init --encryption=none ~/borg/docker_backup`

#### The backup script

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

#### Automatic execution

as root, cron job every day at 3:00</br>
`su` - switch to root</br>
`crontab -e`</br>
`0 3 * * * /home/bastard/borg/borg_backup.sh`</br>
`crontab -l`</br>

# Extra info

Test your backups, test your recovery procedure.

# Remote backup

Backing up borg repo to a network share or cloud using rclone

*To be continued*
