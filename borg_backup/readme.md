# BorgBackup in docker

###### guide by example

### purpose

Backup terminal utility.

* [Official site](https://www.borgbackup.org/)
* [Github](https://github.com/borgbackup/borg)

### files and directory structure

  ```
  /home
  └── ~
      ├── borg_backup
      │    ├── 🗁 docker_backup
      │    ├── 🗋 borg-backup.sh
      │    └── 🗋 borg_backup.log
      │
      └── docker
          ├── container #1
          ├── container #2
          └── ...
  ```

### borg-backup.sh

  `borg-backup.sh`

  ```
  #!/bin/bash

  # INITIALIZE THE REPO WITH THE COMMAND:
  #   borg init --encryption=none /mnt/C1/backup_borg/
  # THEN RUN THIS SCRIPT

  # -----------------------------------------------

  BACKUP_THIS='/home/spravca/docker /etc'
  REPOSITORY='/home/spravca/borg_backup/docker_backup'
  LOGFILE='/home/spravca/borg_backup/borg_backup.log'

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
  borg list $REPOSITORY >> $LOGFILE
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

### automatic execution

* make the script executable `chmod +x borg-backup.sh`

* cron job, every day at 3:00

    `crontab -e`

    `0 3 * * * /home/bastard/borg_backup/borg-backup.sh`
