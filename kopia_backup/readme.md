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

Written in golang.

In this setup kopia cli is installed directly on the host system.</br>
A script is created that backs up the entire docker directory and /etc locally.</br>
Systemd service and timer are used to run the backup periodicly.

# Some aspects of Kopia

* backup configuration is stored in a repository where backups will be stored<br>
  this includes global policy, that is global in sense of repo, not all of kopia
* you connect and disconnect from a repository before working with it,<br>
  only one repository can be connected at time
* currently to ignore some folders, one can create `CACHEDIR.TAG` with specific
  [content](https://bford.info/cachedir/) and set policy: `--ignore-cache-dirs true`
* Maintence is automatic
* ..

# Files and directory structure

```
/home/
│ └── ~/
│     └── docker/
│         ├── container-setup #2
│         ├── container-setup #1
│         ├── ...
│
/mnt/
│ └── mirror/
│      └── KOPIA/
│            └── arch_docker_host/
│
/opt/
  └── kopia-backup-home-etc.sh
```

# The setup

#### install kopia

for arch linux, kopia is on AUR `yay kopia-bin`

#### repo creation and policy 

use of sudo so that kopia has access everywhere<br>
config files are therefore in `/root/config/kopia`

- `sudo kopia policy get --global`
- `sudo kopia policy list`
- `sudo kopia policy set --global --ignore-cache-dirs true --keep-annual 1 --keep-monthly 6 --keep-weekly 4 --keep-daily 14 --keep-hourly 0 --keep-latest 14`



- `mkdir -p /mnt/mirror/KOPIA/docker_host_kopia`</br>
- `sudo kopia repository create filesystem --path /mnt/mirror/KOPIA/docker_host_kopia`<br>
- `sudo kopia repository connect filesystem --path /mnt/mirror/KOPIA/docker_host_kopia`<br>
- `sudo kopia repository status`
- `sudo kopia snapshot create /home/spravca/docker /etc`<br>
- `sudo kopia snapshot list`<br>
- `sudo kopia mount k7e2b0a503edd7604ff61c68655cd5ad7 /mnt/tmp &`<br>
- `sudo umount /mnt/tmp`<br>

#### the backup script

`/opt/kopia-backup-home-etc.sh`
```
#!/bin/bash

#sudo kopia policy set --global --keep-annual 1 --keep-monthly 6 --keep-weekly 4 --keep-daily 14 --keep-hourly 0 --keep-latest 14

REPOSITORY_PATH='/mnt/mirror/KOPIA/docker_host_kopia'
BACKUP_THIS='/home /etc'
export KOPIA_PASSWORD='aaa'

kopia repository connect filesystem --path $REPOSITORY_PATH
kopia snapshot create $BACKUP_THIS
kopia repository disconnect
```

### Automatic execution using systemd


# Accessing the backup files



# Mounting using systemd

* the name of mount and automount files MUST correspond with the path<br>
  instead of `/` a `-` is used, but otherwise it must be the mounting path in name
* for mounting that does not fail on boot, and mounts the target only on request
  enable automount file, not mount file, so:<br>
  `sudo systemctl enable mnt-mirror.automount`

`mnt-mirror.mount`
```ini
[Unit]
Description=3TB truenas mirror mount

[Mount]
What=//10.0.19.11/Mirror
Where=/mnt/mirror
Type=cifs
Options=rw,username=kopia,password=aaa,file_mode=0644,dir_mode=0755,uid=1000,gid=1000

[Install]
WantedBy=multi-user.target
```

`mnt-mirror.automount`
```ini
[Unit]
Description=3TB truenas mirror mount

[Automount]
Where=/mnt/mirror

[Install]
WantedBy=multi-user.target
```

# Remote backup


