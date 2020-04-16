# BorgBackup in docker

###### guide by example

## purpose

Backup terminal utility.

* [Official site](https://www.borgbackup.org/)
* [Github](https://github.com/borgbackup/borg)

## files and directory structure

  ```
  /home
  └── ~
      ├── borg_backup
      │    ├── 🗁 docker_backup
      │    ├── 🗋 borg-backup.sh
      │    └── 🗋 borg_backup.log
      │
      └── docker
          ├── container-setup #1
          ├── container-setup #2
          └── ...
  ```

## The setup

Borg is installed directly on the host system.</br>
A script is created that backs up entire docker directory somewhere locally.</br>
Cronjob executing the script daily.

The script needs manual initialization of a repo somewhere.</br>


* **Install borg backup**

* **The script**

  Repo needs to be initialized manualy first.</br>


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
  the script must be **executabe** - `chmod +x borg-backup.sh`

* **automatic execution**

  cron job, every day at 3:00</br>
  `crontab -e`
  `0 3 * * * /home/bastard/borg_backup/borg-backup.sh`

## Remote backup

Backing up to network share or cloud, rclone
