# Kopia

###### guide-by-example

![logo](https://i.imgur.com/A2mosM6.png)


WORK IN PROGRESS<br>
WORK IN PROGRESS<br>
WORK IN PROGRESS<br>

# Content

* [Kopia on a linux machine](#Kopia-on-a-linux-machine)
* [Kopia on a Windows machine](#Kopia-on-a-windows-machine)
* [Kopia in Docker](#Kopia-in-Docker)

# Purpose & Overview

Backups.

* [Official site](https://kopia.io/)
* [Official Forum](https://kopia.discourse.group/)
* [Github](https://github.com/kopia/kopia)

Kopia is a new open source backup utility with basically **all** modern features.</br>
Cross-platform, deduplication, encryption, compression, multithreaded speed,
native cloud storage support, repository replication, snapshots mounting,
GUI versions, server version,...

Written in golang.<br>
Embedded webGUI for server mode is done in React. KopiaUI comes with electron.

### Ways to use Kopia

* **cli** - Command line.<br>
  You call the kopia binary passing some commands, it executes stuff, done.<br>
  Deployment requires extra work - scripts with configs, scheduling.
* **Kopia Server** - kopia binary runs in the server mode.<br> 
  Runs in the background, with its web server answering at url: `localhost:51515`<br>
  Through the web GUI the management is easier than using cli.
  As an addition to normal backup functions, the server mode can also act
  as a centralized repository for other machines running kopia instances.<br>
  Deployment requires extra work similar to cli, but actual use is through web GUI.
* **KopiaUI** - GUI version.<br>
  KopiaUI comes packaged with electron to provide the feel of a standalone desktop app.<br>
  Good for simple deployment where average user just wants to backup stuff.<br>
  Benefits over cli or server is easier setup and management.<br>
  Drawback is that it runs under one user and only when that user is logged in.
* **Kopia in Docker** - Kopia Server running in docker<br>
  Can fulfill two needs:
  * Backup docker-host stuff to a cloud or a mounted network storage.
    Managed through webgui instead of cli.
  * A centralized kopia repository where other machines on the network,
    that also use kopia, backup their data.

![repo_first](https://i.imgur.com/rbqhmzZ.png)

# Some aspects of Kopia

[Official Getting Started Guide](https://kopia.io/docs/getting-started/)<br>
[Kopia Build Architecture](https://github.com/kopia/kopia/blob/master/BUILD.md)<br>
[Official Features](https://kopia.io/docs/features/)

* Kopia is a single ~35MB binary file.
* Backups are stored in a **repository** that needs to be created first,
  and is always encrypted.<br>
  Before any action, Kopia needs to connect to a repo.
* **Snapshots**, apart from typical meaning, kopia also uses the term for
  targets(paths) that are being backed up.
* **Policy** is a term used to define behavior of the backup/repo,
  like backups retention, what to ignore, logging, scheduling(server/UI),
  actions before and after backup,...
* **Policies** are stored inside a repo and can apply at various levels and
  can **inherit** from each other
  - **Global** policy, the default that comes predefined during repo creation,
    can be edited like any other.
  - Per user policy, per machine policy.
  - Snapshot level policy, only applying for that one path.
* **Maintenance** is automatic
* During snapshots Kopia uses local **cache**, location varies depending on the OS.
  Default max size is 5GB, but it gets swept periodically every few minutes.<br>
  Useful commands are `kopia cache info` and `kopia cache clear`
* [Here's](https://kopia.discourse.group/t/trying-to-understand-retention-policies/164/4)
  how **retention** works under the hood.<br>
* ..

# Kopia on a linux machine

![list_snapshots_cli](https://i.imgur.com/lQ8W5yh.png)

cli version of kopia will be used to periodically backup to a mounted network storage.<br>
The backup script will be executed using systemd-timers for scheduling.

### Install Kopia

For arch linux, kopia is on AUR `yay kopia-bin`

### The initial steps and general use commands

* **repo creation**

`mkdir -p /mnt/mirror/KOPIA/docker_host_kopia`<br>
`sudo kopia repo create filesystem --path /mnt/mirror/KOPIA/docker_host_kopia`<br>
`sudo kopia repo connect filesystem --path /mnt/mirror/KOPIA/docker_host_kopia`<br>
`sudo kopia repo status`<br>

* **the policy info and change**

`sudo kopia policy get --global`<br>
`sudo kopia policy list`<br>
`sudo kopia policy set --global --keep-annual 2 --keep-monthly 6 --keep-weekly 4 --keep-daily 14 --keep-hourly 0 --keep-latest 3`<br>

* **manual run**

`sudo kopia snapshot create /home/spravca/docker /etc`<br>
`sudo kopia snapshot list`<br>

* **mounting a backup**

`sudo kopia mount all /mnt/tmp &` - mounts all snapshots<br>
`sudo kopia snapshot list`<br> 
`sudo kopia mount k7e2b0a503edd7604ff61c68655cd5ad7 /mnt/tmp &`<br>
`sudo umount /mnt/tmp`<br>

### The backup script

In linux, passing multiple paths separated by space seems to work fine.<br>
So both `/home` and `/etc` are set to be backed up.

`/opt/kopia-backup-home-etc.sh`
```bash
#!/bin/bash

# initialize repository
#   sudo kopia repo create filesystem --path /mnt/mirror/KOPIA/docker_host_kopia
# adjust global policy
#   sudo kopia policy set --global --keep-annual 2 --keep-monthly 6 --keep-weekly 4 --keep-daily 14 --keep-hourly 0 --keep-latest 3

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


<details>
<summary><h3>Mounting network storage using systemd</h3></summary>

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

</details>

---
---

# Kopia on a Windows machine

![windows_snapshot_history_gui](https://i.imgur.com/nqkng5k.png)

## Kopia Server on Windows

* Download this repo, keep `kopia_server_deploy_win` folder, delete rest.
* Run `DEPLOY.cmd`, it will:
  * Removes powershell scripts restriction.
  * Creates folder `C:\Kopia` and kopies files there
  * Imports a task schedule that will start `C:\Kopia\kopia_server_start.cmd`<br>
    Can edit flags used for the server.
  * Places kopia.url on the current user desktop
* visit in browser `localhost:51515`
* setup repo
* setup what to backup and schedule

Kopia should now run on boot and be easy to manage through web GUI.<br>
Be it creating backup jobs, mounting old snapshots, or just looking around
if all works as it should.

It is also popular to use nssm to start up and manage kopia as a service.<br>

While Kopia runs now in server mode, the fact that we pass `--insecure` flag
means it cant serve as a repository for other kopia instances.
For that look at docker deployment section or in to making changes too.


<details>
<summary><h2>Kopia cli on Windows</h2></summary>

![windows_scoop_install_kopia](https://i.imgur.com/UPZFImh.png)

*Written before I realiezed I could be using kopia server.*<br>
*Also, at the moment its the only way I know how to make actions work for VSS snapshots.*

While KopiaUI version seems like the way to go I really dislike the idea 
of not having trust in kopia if using it on servers that run with users
logged out. Since KopiaUI works only if user is logged in. 

* Download this repo, keep `kopia_cli_deploy_win` folder, delete rest.
* Run `DEPLOY.cmd`, it will:
  * Removes powershell scripts restriction.
  * kopies kopia.exe in to `C:\Windows\System32`
  * Creates folder `C:\Kopia` and kopies there<br>
    `kopia_backup_scipt.ps1` and the VSS ps1 before and after files.
  * imports a task schedule
* Open the `kopia_backup_scipt.ps1` and follow the instructions there.<br>
  Which is just to create repo before running the script.<br>
  `kopia repo create filesystem --path C:\kopia_repo --password aaa`
* edit the scheduled task to the prefered time, default is daily at 21:19
* run scheduled task manually
* check if it worked
  * `kopia repo status`
  * `kopia snap list --all` 

### VSS snapshots

To make use of VSS snapshots before running backup execute these two commands,
replacing `C:\Test` with the snapshot target path.<br>

* `kopia policy set C:\Test --before-folder-action "powershell -WindowStyle Hidden C:\Kopia\win_vss_before.ps1"`
* `kopia policy set C:\Test --after-folder-action  "powershell -WindowStyle Hidden C:\Kopia\win_vss_after.ps1"`

Note the use of `--enable-actions` in the backup script `kopia_backup_scipt.ps1`,
which is required for actions to work.

### Kopia install using scoop, machine-wide

Just something to have note of, if decided to switch to heavy scoop use.

* open terminal as admin
* `Set-ExecutionPolicy Bypass`
* `iex "& {$(irm get.scoop.sh)} -RunAsAdmin"`
* `scoop install sudo --global`
* `sudo scoop install kopia --global`

</details>

---
---

# Kopia in Docker

![kopia_docker_logs](https://i.imgur.com/w57KHvp.png)

### Files and directory structure

```
/mnt/
└── mirror/
    
/home/
└── ~/
    └── docker/
        └── kopia/
            ├── kopia_config/
            ├── kopia_cache/
            ├── kopia_logs/
            ├── some_data/
            ├── kopia_repository/
            ├── kopia_tmp/
            ├── .env
            └── docker-compose.yml
```

* `/mnt/mirror/...` - a mounted network storage share
* `kopia_config/` - repository.config and ui-preferences.json 
* `kopia_cache/` - cache 
* `kopia_logs/` - logs 
* `some_data/` - some data to be backed up
* `kopia_repository/` - repository location 
* `kopia_tmp/` - temp used for snapshots
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

### docker-compose

The data to be backed up are mounted in read only mode.<br>
To be able to mount snapshots, extra privilages are required and fuse access.

```
services:

  kopia:
    image: kopia/kopia:latest
    container_name: kopia
    hostname: kopia
    restart: unless-stopped
    env_file: .env
    privileged: true
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    devices:
      - /dev/fuse:/dev/fuse:rwm
    ports:
      - "51515:51515"
    command:
      - server
      - start
      - --tls-generate-cert
      - --disable-csrf-token-checks
      - --address=0.0.0.0:51515
      - --server-username=$USERNAME
      - --server-password=$KOPIA_PASSWORD
    volumes:
        # Mount local folders needed by kopia
        - ./kopia_config:/app/config
        - ./kopia_cache:/app/cache
        - ./kopia_logs:/app/logs
        # Mount local folders to snapshot
        - ./some_data:/data:ro
        # Mount repository location
        - /mnt/mirror/kopia_repository:/repository
        # Mount path for browsing mounted snaphots
        - ./kopia_tmp:/tmp:shared

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true
```


`.env`
```bash
DOCKER_MY_NETWORK=caddy_net
TZ=Europe/Bratislava

# KOPIA
USERNAME=admin
KOPIA_PASSWORD=aaa
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

### Reverse proxy

Caddy is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

To function as a repository server, Kopia must be setup with https,
which is achieved by using `--tls-generate-cert` flag and removal
of `--insecure` flag.

So now Kopia sits behind Caddy, but caddy needs to be told the traffic is
https and to ignore that the certificate is not valid.

`Caddyfile`
```
kopia.{$MY_DOMAIN} {
  reverse_proxy kopia:51515 {
    transport http {
      tls
      tls_insecure_skip_verify
    }
  }
}
```

### First run

![kopia_repo_setup_first_run](https://i.imgur.com/mnn66Hj.png)

* visit kopia.example.com
* create new repository as `Local Directory or NAS`, set path to `/repository`,
  set password

Now this container can do backups of mounted stuff in to other mounted places
or cloud, while managed through webgui.

To also make it function as a repository server a user account needs to be added.
The users are stored in the repo.

* exec in to the container<br>
  `docker container exec -it kopia /bin/bash`
* add user@machine and set the password<br>
  `kopia server user add user1@machine1`
* on another machine test with koppiaUI, on the first run:<br>
  * Pick `Kopia Repository Server`
  * Server address: `https://kopia.example.com:443`
  * *Trusted server certificate fingerprint (SHA256)*<br>
    can be left empty, or if you put something there, it gives you error
    where it tells you fingerprints of the server to pick from.
  * In advanced option one can override user@machine with the one set
    when exec-ed in to the docker container.
    Or exec again there and add another one.

### Troubleshooting

* check kopia docker container logs, I like using [ctop](https://github.com/bcicen/ctop)
* `nslookup kopia.example.com` check if you are getting to you server from client
* Make sure you use port 443 in server address. 

