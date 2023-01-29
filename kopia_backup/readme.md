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

Kopia is a very new open source backup utility with basicly **all** modern features.</br>
Cross-platform, deduplication, encryption, compression, multithreaded speed,
fully build in cloud storage support, GUI versions, snapshots mounting,...

Written in golang.

In this setup kopia cli is installed directly on a docker host.</br>
A kopia repository is set up.<br>
A script that backs up data is scheduled to run regularly<br>
Bonus info on mounting remote NAS storage on boot using systemd<br>

# Some aspects of Kopia

* Backup configuration is stored in a repository where backups are stored.<br>
  This includes global policy, that is global in sense of a repo, not all of kopia.
* You connect to a repository before using it, and disconnect afterwards.<br>
  Only one repository can be connected at the time(at least for cli version).
* Currently to ignore a folder - `CACHEDIR.TAG` file can be placed inside,
  with specific [content](https://bford.info/cachedir/) 
  and set policy: `--ignore-cache-dirs true`
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

only the script `kopia-backup-home-etc.sh` in /opt is created<br>
uf, systemd unit files too, but I am not "drawing" /etc/systemd/system/ up there...
even this will probably get deleted

# The setup

### install kopia

for arch linux, kopia is on AUR `yay kopia-bin`

### the initial steps


use of sudo so that kopia has access everywhere<br>

* **the policy info and change**

`sudo kopia policy get --global`<br>
`sudo kopia policy list`<br>
`sudo kopia policy set --global --ignore-cache-dirs true --keep-annual 1 --keep-monthly 6 --keep-weekly 4 --keep-daily 14 --keep-hourly 0 --keep-latest 14`<br>

* **repo creation**

`mkdir -p /mnt/mirror/KOPIA/docker_host_kopia`<br>
`sudo kopia repository create filesystem --path /mnt/mirror/KOPIA/docker_host_kopia`<br>
`sudo kopia repository connect filesystem --path /mnt/mirror/KOPIA/docker_host_kopia`<br>
`sudo kopia repository status`<br>

* **manual run**

`sudo kopia snapshot create /home/spravca/docker /etc`<br>
`sudo kopia snapshot list`<br>

* **mounting a backup**

`sudo kopia snapshot list`<br>
`sudo kopia mount k7e2b0a503edd7604ff61c68655cd5ad7 /mnt/tmp &`<br>
`sudo umount /mnt/tmp`<br>

### the backup script

`/opt/kopia-backup-home-etc.sh`
```bash
#!/bin/bash

#sudo kopia policy set --global --ignore-cache-dirs true --keep-annual 1 --keep-monthly 6 --keep-weekly 4 --keep-daily 14 --keep-hourly 0 --keep-latest 14

REPOSITORY_PATH='/mnt/mirror/KOPIA/docker_host_kopia'
BACKUP_THIS='/home /etc'
export KOPIA_PASSWORD='aaa'

kopia repository connect filesystem --path $REPOSITORY_PATH
kopia snapshot create $BACKUP_THIS
kopia repository disconnect
```

### Automatic execution using systemd

Usually cron is used, but systemd provides better logging and control,
so better get used to using it.<br>
[Heres](https://github.com/kopia/kopia/issues/2685#issuecomment-1384524828)
some discussion on units. Will be editing it for ntfy 

[ntfy](https://github.com/binwiederhier/ntfy) is used for notifications,
more info [here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal#linux-systemd-unit-file-service)

```kopia-home-etc.service```
```ini
[Unit]
Description=kopia backup
Wants=network-online.target
After=network-online.target
ConditionACPower=true
OnFailure=ntfy@failure-%p.service
# OnSuccess=ntfy@success-%p.service

[Service]
Type=oneshot

# Lower CPU and I/O priority.
Nice=19
CPUSchedulingPolicy=batch
IOSchedulingPriority=7

IPAccounting=true
PrivateTmp=true
Environment="HOME=/root"

ExecStart=/opt/kopia-backup-home-etc.sh
```


```kopia-home-etc.timer```
```
[Unit]
Description=Run kopia backup

[Timer]
OnCalendar=*-*-* 02:00:00
RandomizedDelaySec=10min
Persistent=true

[Install]
WantedBy=timers.target
```

# Mounting backup storage using systemd

* file are placed in `/etc/systemd/system`
* the name of mount and automount files MUST correspond with the path<br>
  instead of `/` a `-` is used, but otherwise it must be the mounting path in name
* for mounting that does not fail on boot if network there are network issues,
  and mounts the target only on request - enable `automount` file,
  not `mount` file, so:<br>
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


