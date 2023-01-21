# Kopia

###### guide-by-example

![logo](https://i.imgur.com/A2mosM6.png)

WORK IN PROGRESS<br>
WORK IN PROGRESS<br>
WORK IN PROGRESS<br>

# Purpose & Overview

Backups.

* [Official site](https://kopia.io/)
* [Github](https://github.com/kopia/kopia)

Kopia is an open source backup utility with basicly all modern features.</br>
Cross-platform, deduplication, encryption, compression, multithreaded speed,
cloud storage support, CLI and GUI versions, snapshots mounting,...

Written in golang,

In this setup kopia cli is installed directly on the host system.</br>
A script is created that backs up the entire docker directory and /etc locally.</br>
Cronjob is set to execute this script daily.

The repository is also pruned on each run of the script -
old archives are deleted while keeping the ones fitting the retention rules
in the script.</br>
One backup per day for last 7 days, last 4 weeks, last 6 months are kept.

# Files and directory structure

```
/home/
├── ~/
│   └── docker/
│       ├── container-setup #2
│       ├── container-setup #1
│       ├── ...
│
/mnt/
  └── mirror/
        └── docker_host_kopia/

```

* `docker_backup/` - borg repository directory containg the backups
* `borg_backup.sh` - the backup script that adds new archive in to the repository
* `borg_backup.log` - log file with the dates of backups

Only `borg_backup.sh` has to be provided.</br>
Repo directory is created by `borg init` command
and the log file is created on the first run.


# The setup

#### Install kopia

for arch linux, kopia is on AUR `yay kopia-bin`

#### Backing up using kopia

use of sudo so that kopia has access everywhere<br>
config files are therefore in `/root/config/kopia`

- `mkdir /mnt/mirror/docker_host_kopia`</br>
- `sudo kopia repository create filesystem --path /mnt/mirror/docker_host_kopia`<br>
- `sudo kopia repository connect filesystem --path /mnt/mirror/docker_host_kopia`<br>
- `sudo kopia snapshot create /home/spravca/docker`<br>
- `sudo kopia snapshot list`<br>
- `sudo kopia mount k7e2b0a503edd7604ff61c68655cd5ad7 /mnt/tmp &`<br>
- `sudo umount /mnt/tmp`<br>


#### The backup script




### Manual run


### Automatic execution


# Accessing the backup files


# Extra info


# Remote backup


