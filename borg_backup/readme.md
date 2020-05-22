# BorgBackup in docker

###### guide-by-example

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

* `docker_backup/` - borg repository directory containg the backups
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

Note the sudo. Borg commands should be run as root, so it can access everything.

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

The script must be **executabe** - `chmod +x borg_backup.sh`

### Manual run

`sudo ./borg_backup.sh`

It could ask about
*Attempting to access a previously unknown unencrypted repository*</br>
Answer yes.</br>
If we would initialize the repo with sudo then it would be no issue,
but then non root user would not be able to enter the repo directory.

### Automatic execution

Using [cron](https://wiki.archlinux.org/index.php/cron).

**Make sure cron is installed and the service is running**</br> 
`sudo systemctl status cronie`

Create a cron job that executes the script
[at 03:00](https://crontab.guru/#0_03_*_*_*) 

* switch to root</br>
  `su`
* add new cron job</br>
  `crontab -e`</br>
  `0 3 * * * /home/bastard/borg/borg_backup.sh`


`crontab -l` - list current cronjobs</br>
`journalctl -u cronie` - cron history


# Accessing the backup files

* go in to the borg repo</br>
  `cd /home/bastard/borg/docker_backup/`
* list the archives</br>
  `sudo borg list .`
* choose one by the date, copy its identifier which is epoch time, e.g. 1588986941
* mount it to some folder</br>
  `sudo borg mount .::1588986941 /mnt/temp`
* browse the directory where the archive is mounted and do whatever is needed
* umount the backup</br>
  `sudo borg umount /mnt/temp`

# Extra info

Test your backups, test your recovery procedure.

# Remote backup

Backing up borg repo to a network share or cloud using rclone

*To be continued*
