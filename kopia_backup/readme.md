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

Kopia is a new open source backup utility with basicly **all** modern features.</br>
Cross-platform, deduplication, encryption, compression, multithreaded speed,
native cloud storage support, repository replication, snapshots mounting,
GUI versions, server version,...

Written in golang.

# Some aspects of Kopia

There are 3 ways to go about running kopia

* **cli** - Command line.<br>
  You call the binary passing some commands, it executes stuff, done.<br>
  Requires extra work - scripts with configs, scheduling.
* **KopiaUI** - GUI version of kopia.<br>
  Easier managment, takes uppon itself scheduling.<br>
  Drawback is that it runs under one user and only when logged in.
* **Kopia Server** - running kopia and its webserver in the background<br>
  Managment through web browser at an url, can run as a docker container.

[Official Getting Started Guide](https://kopia.io/docs/getting-started/)<br>
[Official Features](https://kopia.io/docs/features/)

* Kopia is a single ~35MB binary file.
* Backups are stored in a **repository** that needs to be created first,
  and is always encrypted - requires password.
  * Before any action, Kopia needs to connecto to a repo.
* **Snapshot**, appart from typical meaning, kopia also uses it to for
  targets(paths) to be backed up.
* **Policy** is a term used to define behaviour of the backup/repo,
  like backups retention, what to ignore, logging, scheduling(server/UI),
  actions before and after backup,...
* **Policies** are stored inside a repo and can apply at various levels and
  can inherit from each other
  - global policy, the default that comes predefined during repo creation
  - per user policy and per machine policy
  - snapshot level policy, only applying for that one path
* Maintence is automatic
* ..

# Kopia on a linux machine

cli version of kopia will be used, with a script and systemd-timers for scheduling.

### install kopia

for arch linux, kopia is on AUR `yay kopia-bin`

### the initial steps

General use of sudo so that kopia has access everywhere.

* **repo creation**

`mkdir -p /mnt/mirror/KOPIA/docker_host_kopia`<br>
`sudo kopia repo create filesystem --path /mnt/mirror/KOPIA/docker_host_kopia`<br>
`sudo kopia repo connect filesystem --path /mnt/mirror/KOPIA/docker_host_kopia`<br>
`sudo kopia repo status`<br>

* **the policy info and change**

`sudo kopia policy get --global`<br>
`sudo kopia policy list`<br>
`sudo kopia policy set --global --ignore-cache-dirs true --keep-annual 1 --keep-monthly 6 --keep-weekly 4 --keep-daily 14 --keep-hourly 0 --keep-latest 14`<br>

* **manual run**

`sudo kopia snapshot create /home/spravca/docker /etc`<br>
`sudo kopia snapshot list`<br>

* **mounting a backup**

`sudo kopia mount all /mnt/tmp &` - mounts all snapshots<br>
`sudo kopia snapshot list`<br> 
`sudo kopia mount k7e2b0a503edd7604ff61c68655cd5ad7 /mnt/tmp &`<br>
`sudo umount /mnt/tmp`<br>

### The backup script

`/opt/kopia-backup-home-etc.sh`
```bash
#!/bin/bash

#sudo kopia policy set --global --keep-annual 1 --keep-monthly 6 --keep-weekly 4 --keep-daily 14 --keep-hourly 0 --keep-latest 14

REPOSITORY_PATH='/mnt/mirror/KOPIA/docker_host_kopia'
BACKUP_THIS='/home /etc'
KOPIA_PASSWORD='aaa'

kopia repository connect filesystem --path $REPOSITORY_PATH --password $KOPIA_PASSWORD
kopia snapshot create $BACKUP_THIS
kopia repository disconnect
```
make the script executable<br>
`sudo chmod +x /opt/kopia-backup-home-etc.sh`

### Scheduled backups using systemd

Usually cron is used, but systemd provides better logging and control,
so better get used to using it.<br>
[Heres](https://github.com/kopia/kopia/issues/2685#issuecomment-1384524828)
some discussion on unit files.<br>
[ntfy](https://github.com/binwiederhier/ntfy) can be used for notifications,
more info [here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal#linux-systemd-unit-file-service)

* `sudo micro /etc/systemd/system/kopia-home-etc.service`

```kopia-home-etc.service```
```ini
[Unit]
Description=kopia backup
Wants=network-online.target
After=network-online.target
ConditionACPower=true
# OnFailure=ntfy@failure-%p.service
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

* `sudo micro /etc/systemd/system/kopia-home-etc.timer`

```kopia-home-etc.timer```
```ini
[Unit]
Description=Run kopia backup

[Timer]
OnCalendar=*-*-* 02:00:00
RandomizedDelaySec=10min
Persistent=true

[Install]
WantedBy=timers.target
```

* `sudo systemctl enable --now kopia-home-etc.timer`
* `systemctl status kopia-home-etc.timer`
* `journalctl -u kopia-home-etc.timer` - see history

# Mounting network storage using systemd

* files are placed in `/etc/systemd/system`
* the name of mount and automount files MUST correspond with the path<br>
  replacing `/` with a `-`,
  but otherwise it must be the mounting path in the name
* for mounting that does not fail on boot if there are network issues,
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

...  some day ...

# Kopia in Windows

## Kopia Server on Windows

* download this repo, delete shit, keep `kopia_server_deploy` folder
* run `DEPLOY.cmd`, it will
  * Removes powershell scripts restriction.
  * Creates folder `C:\Kopia` and kopies files there
  * imports a task schedule that will start Kopia Server at boot
* visit in browser `localhost:51515`
* setup repo
* setup what to backup and schedule
* edit the `kopia_backup_scipt.ps1`, set what to backup and where
* for the same repo location execute<br>
  `sudo kopia repository create filesystem --path C:\Backup`
* run the script

## Kopia cli on Windows


While GUI version seems like a way to go.. IMO its not there yet.
The schedule seems to be dependant on user logging in... 
and general weird feeling of poor GUI quality.

So here goes cli version. As after some hands-on experience with cli version
the GUI version might click in better too, later.

* download this repo, delete shit, keep `kopia-deploy` folder
* run `DEPLOY.cmd`, it will
  * Removes powershell scripts restriction.
  * Install scoop, sudo, kopia.
  * Creates folder `C:\Kopia` and kopies there<br>
    `kopia_backup_scipt.ps1` and the VSS ps1 before and after files.
  * imports a task schedule
* edit the `kopia_backup_scipt.ps1`, set what to backup and where
* for the same repo location execute<br>
  `sudo kopia repository create filesystem --path C:\Backup`
* run the script

To do the above things manualy:

* install kopia using scoop
  * open terminal as admin
  * `Set-ExecutionPolicy RemoteSigned`
  * `iex "& {$(irm get.scoop.sh)} -RunAsAdmin"`
  * `scoop install sudo --global`
  * `sudo scoop install kopia --global`
* download this repo, extract to `c:\kopia`  
* edit kopia-backup-home-etc.sh as see fit

* powershell as as administrator
* --enable-actions
* in tray, right click on the icon - `Launch At Startup`<br>
  this creates registry entry - *HKCU\Software\Microsoft\Windows\CurrentVersion\Run\KopiaUI*
* 

kopia policy set <target_dir> --before-folder-action "powershell -WindowStyle Hidden <path_to_script>\before.ps1"
kopia policy set <target_dir> --after-folder-action  "powershell -WindowStyle Hidden <path_to_script>\after.ps1"




