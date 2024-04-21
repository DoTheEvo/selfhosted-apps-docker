# Kopia

###### guide-by-example

![logo](https://i.imgur.com/A2mosM6.png)

# Content

* [Kopia in Linux](#Kopia-in-Linux)
* [Kopia in Windows](#Kopia-in-Windows)
* [Kopia in Docker](#Kopia-in-Docker)
* [Kopia backup to Cloud](#Kopia-backup-to-Cloud)

# Purpose & Overview

Backups.

* [Official site](https://kopia.io/)
* [Official Forum](https://kopia.discourse.group/)
* [Github](https://github.com/kopia/kopia)

Kopia is a new open source backup utility with basically **all** modern features.</br>
Cross-platform, deduplication, encryption, compression, multithreaded speed,
native cloud storage support, repository replication, snapshots mounting,
GUI version, server version,...

Written in golang.<br>
Embedded webGUI for server mode is done in React. KopiaUI comes packaged with electron.

### Ways to use Kopia

* **cli** - Command line.<br>
  You call the kopia binary passing some commands, it executes stuff, done.<br>
  Deployment requires extra work - scripts with configs, scheduling.
* **KopiaUI** - GUI version.<br>
  Kopia that comes packaged with electron for GUI to provide the feel of a standalone desktop app.<br>
  Good for simple deployment where average user just wants to backup stuff.<br>
  Benefits over cli is much easier setup, management and ability to connect to  multiple repos once.<br>
  Drawback is that it runs under one user and only when that user is logged in.
* **Kopia Server** - kopia binary runs in a server mode.<br> 
  Runs in the background, now with its web server answering at url: `localhost:51515`<br>
  Web GUI at the url makes the management easy so it can replace KopiaUI.<br>
  But the main purpose of server mode is that Kopia instance can now serve
  as a centralized repository for other machines that run their Kopia instances
  and select server's url as repository where to backup.<br>
  Deployment requires extra work similar to cli, but actual use is through web GUI.
* **Kopia in Docker** - Kopia Server running in docker<br>
  Can fulfill two needs:
  * A centralized Kopia repository where other machines on the network,
    that also use Kopia, backup their data.
  * Backup docker-host stuff to a cloud or a mounted network storage.
    Managed through webgui instead of cli.

![repo_first](https://i.imgur.com/rbqhmzZ.png)

# Some aspects of Kopia

[Official Getting Started Guide](https://kopia.io/docs/getting-started/)<br>
[Features](https://kopia.io/docs/features/)<br>
[Advanced Topics](https://kopia.io/docs/advanced/)

The above linked documentation is well written and worth a look
if planning serious use.

* Kopia is a single ~35MB binary file.
* Backups are stored in a **repository** that needs to be created first,
  and is always encrypted.
* Before any action, Kopia needs to be **connected to a repo** as repos store most of 
  the settings(policies), and commands are executed in their context.
  Multiple machines can be connected simultaneously.
* **Snapshots**, is the term used by Kopia for targets(paths) that are being backed up.
* **Policy** - settings for repo/backup behaviour, stuff like backups retention,
  what to ignore, logging, scheduling(server/UI), actions before and after backup,...
* **Policies** are stored inside a repo and can apply at various levels and
  can **inherit** from each other
  - **Global** policy, the default that comes predefined during repo creation,
    can be edited like any other.
  - Per user@machine policy
  - Snapshot level policy, only applying for that one path.
* **Maintenance** is automatic.
* **Retention** of backups - [here's](https://kopia.discourse.group/t/trying-to-understand-retention-policies/164/4)
  how it works under the hood.<br>
* **Restore** from backups is most easily done by mounting a snapshot.<br>
  Web GUI versions have button for it, cli version can do `sudo kopia mount all /mnt/temp &`
* **Tasks** section in gui gets wiped when Kopia closes, info on snapshots run
  history and duration then has to be find in logs
* **Logs** are creted on every execution of kopia binary.<br>
  They rotate by default with max age 30 days, but still can grow hundreds of MB.
* [Compression](https://kopia.io/docs/advanced/compression/) is good and 
  should be set before backup starts. My go-to is `zstd-fastest`. If backups
  feel slow `s2-default` is less cpu heavy but with worse compression.
  Useful command: `kopia content stats`
* During snapshots Kopia uses local **cache**, location varies depending on the OS.
  Default max size is 5GB. Cache gets swept periodically every few minutes.<br>
  Useful commands are `kopia cache info` and `kopia cache clear`.
* Increase [considerably the max cache size](https://github.com/kopia/kopia/issues/3059#issuecomment-1663479603)
  if planning to use cloud storage as the maintenance could eat into egress cost
  when kopia redownloads files.
* ...


# Kopia in Linux

![list_snapshots_cli](https://i.imgur.com/lQ8W5yh.png)

A script will be periodically executing cli version of kopia to connect to a repository,
execute backup, and disconnect.<br>
Systemd-timers are used to schedule execution of the script.
The repository is created on a network share, also mounted on boot using systemd.

### Install Kopia

For arch linux, kopia is on AUR `yay kopia-bin`

### The initial steps and general use commands

* **repo creation**


`sudo kopia repo create filesystem --path /mnt/mirror/KOPIA/docker_host_kopia`<br>
`sudo kopia repo connect filesystem --path /mnt/mirror/KOPIA/docker_host_kopia`<br>
`sudo kopia repo status`

If the path used during creation does not exists, kopia will create it in full.<br>
After creation the repo is connected, so connnect command is just demonstration. 

* **the policy info and change**

`sudo kopia policy list`<br>
`sudo kopia policy show --global`<br>
`sudo kopia policy set --global --compression=zstd-fastest --keep-annual=0 --keep-monthly=12 --keep-weekly=0 --keep-daily=14 --keep-hourly=0 --keep-latest=3`<br>

* **manual backup run**

`sudo kopia snapshot create /home/spravca/docker /etc`<br>
`sudo kopia snapshot list`<br>

Since the connection exists with a repo,
all that is needed is target that should be backed up.

* **mounting backups**

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

# v0.2
# initialize repository
#   sudo kopia repo create filesystem --path /mnt/mirror/KOPIA/docker_host_kopia
# for cloud like backblaze
#   sudo kopia repository create b2 --bucket=rakanishu --key-id=001496285081a7e0000000003 --key=K0016L8FAMRp/F+6ckbXIYpP0UgTky0
#   sudo kopia repository connect b2 --bucket=rakanishu --key-id=001496285081a7e0000000003 --key=K0016L8FAMRp/F+6ckbXIYpP0UgTky0
# adjust global policy
#   sudo kopia policy set --global --compression=zstd-fastest --keep-annual=0 --keep-monthly=12 --keep-weekly=0 --keep-daily=14 --keep-hourly=0 --keep-latest=3

REPOSITORY_PATH='/mnt/mirror/KOPIA/docker_host_kopia'
BACKUP_THIS='/home /etc'
export KOPIA_PASSWORD='aaa'

kopia repository connect filesystem --path $REPOSITORY_PATH
kopia snapshot create $BACKUP_THIS
kopia repository disconnect

# --------------  ERROR EXIT CODES  --------------
# kopia does not interupts its run with an error if target or repository are missing
# this makes systemd OnSuccess OnFailure not behaving as one might expect
# below are checks for paths, that result in immediate error exit code if they do not exist
# they are at the end because some backup might get done even if another is missing something
# we just want the error exit code

IFS=' ' read -ra paths <<< "$BACKUP_THIS"
for path in "${paths[@]}"; do
  if [ ! -e "$path" ]; then
    echo "ERROR: Backup target '$path' does not exist."
    exit 1
  fi
done

if [ ! -d "$REPOSITORY_PATH" ]; then
  echo "ERROR: Directory '$REPOSITORY_PATH' does not exist."
  exit 1
fi
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

### Troubleshooting

To see logs of last Kopia runs done by systemd

* `sudo journalctl -ru kopia-home-etc.service`
* `sudo journalctl -xru kopia-home-etc.service`

![journaclt_output](https://i.imgur.com/46XIFFO.png)

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

# Kopia in Windows

![windows_snapshot_history_gui](https://i.imgur.com/MI16Zp1.png)

## KopiaUI in Windows

KopiaUI does not really need a guide. It's simple and just works for normal use.<br>
But since we are here...

* [Download latest release](https://github.com/kopia/kopia/releases)
* Extract it somewhere, lets say `C:\Kopia`
* Run it, click through repo creation
* set global policy
  * recommend setting compression, `zstd-fastest`
  * set schedule
  * retention rules
* select what to backup
* Right click tray icon and set to "Launch at startup"
* done

It will now start on users login, and executes at set schedule.

While KopiaUI seems like the way to go because of the simple deployment and
use, it has a drawback. The scheduled backups works only when user is logged in.
Which for many deployments feel like it introduces unnecessary uncertainty,
or is not even viable when servers often run with no user logged in. 

## Kopia Server in Windows

My go-to for windows use because it offers gui for easier managment and 
the reliability of always running in the background as a service.

This deployment does not make use of the main Kopia Server feature,
to be a repository for other machines running Kopiam, just local deployment.
Few edits of `kopia_server_start.cmd` can make it happen though.

* [Download this repo](https://github.com/DoTheEvo/selfhosted-apps-docker/archive/refs/heads/master.zip), 
  delete everything except `kopia_backup/kopia_server_deploy_service_win` folder.
* Run `DEPLOY.cmd` as admin, it will:
  * Removes powershell scripts restriction.
  * Creates folder `C:\Kopia` and copies files there.
  * Uses [shawl](https://github.com/mtkennerly/shawl) to create Kopia service.
  * Places `kopia.url` on the current user's desktop.
* One should check content of `C:\Kopia\kopia_server_start.cmd`<br>
  that's where credentials are set, default: `admin // aaa`
* Visit in browser `localhost:51515`
* Setup new repo through webgui.
* set global policy
  * recommend setting compression, `zstd-fastest`
  * set schedule
  * retention rules
* Select what to backup.

Kopia should now run on boot and be easy to manage through web GUI.<br>
Be it creating backup jobs, mounting old snapshots to restore files,
or just looking around if all works as it should.

All relevant files are in `C:\Kopia`, from binaries, `repository.config`, to logs.

Before shawl, task scheduler was used.<br>
This [matushorvath/Kopia as Windows Service](https://gist.github.com/matushorvath/dd7148c201ceae03ddebc1b4bbef4d20)
guide helped move beyond that. It contains more info if one would want to 
actually run as server repository for other machines.<br>
Also use of [nssm](https://nssm.cc/) is popular.

## Kopia cli in Windows

![windows_scoop_install_kopia](https://i.imgur.com/UPZFImh.png)

At the moment **cli is the only way to use VSS snapshots**.

All relevant files are in `C:\Kopia`, from binaries, `repository.config`, to logs.
A scheduled task is imported that executes a powershell script
`C:\Kopia\kopia_backup_scipt.ps1` at 21:19.
The script connects to a set repo and backup set targets.

This approach is bit more hands on than having a gui, but for daily use one
can easily get by with the commands: `kopia snap list -all` and `kopia mount all K:`<br>
Note that if mount command is not working, try executing it in non admin terminal. Weird
windows thing. Or you need to enable/install `WebClient` service.

* [Download this repo](https://github.com/DoTheEvo/selfhosted-apps-docker/archive/refs/heads/master.zip),
  delete everything except `kopia_cli_deploy_win` folder.
* Run `DEPLOY.cmd`
  * Removes powershell scripts restriction.
  * Creates folder `C:\Kopia` and kopies there<br>
    `kopia.exe`, `kopia_backup_scipt.ps1`.
  * Adds `C:\Kopia` to the system env variable PATH.
  * imports a scheduled task.
* Read `kopia_backup_scipt.ps1` and follow the instructions there.<br>
  Which should be to just to create repo before running the script.
* edit the scheduled task to the prefered time, default is daily at 21:19
* run scheduled task manually
* check if it worked
  * `kopia repo status`
  * `kopia snap list --all`

The script is set to save logs in to `C:\Kopia\Kopia_Logs\`.

### VSS snapshots

Volume Shadow Copy Service freezes the state of the disk in time and makes
this snapshot available to use.
This is what allows backup of open files that are in use.<br>
[Here's some youtube video on VSS.](https://youtu.be/RUwocwP2ilI?t=85)

To make use of this feature edit `kopia_backup_scipt.ps1` changing
`$USE_SHADOW_COPY = $false` to `$USE_SHADOW_COPY = $true`

To check if it's set: `kopia policy show --global`,
should see there: *OS-level snapshot support: Volume Shadow Copy: when-available*

Can also check log files, any named snapshot-creat in cli folder, and see 
entries about *volume shadow copy*. Or also one might execute command
`vssadmin list shadows` to see current VSS snapshots and then execute
it again during the backup.

### Kopia install using scoop, machine-wide

Just something to have note of, if decided to switch to heavy scoop use.

* open terminal as admin
* `Set-ExecutionPolicy Bypass`
* `iex "& {$(irm get.scoop.sh)} -RunAsAdmin"`
* `scoop install sudo --global`
* `sudo scoop install kopia --global`

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
To be able to mount snapshots, extra privileges are required and fuse access.

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
  to see container runtime logs, or the ones mounted in logs directory
* DNS issue, check `nslookup kopia.example.com` if on the machine
  is getting correct iP
* Make sure you use port 443 in server address. 


# Kopia backup to Cloud

## Backblaze B2

![backblaze_repo_pic](https://i.imgur.com/Yhi2BpM.png)

[Cheapest](https://www.backblaze.com/cloud-storage/pricing)
cloud storage I believe.<br>
It cost $6 annualy to store 100GB. Any download is charged extra,
that 100GB would cost $1.

[Official Kopia documentation](https://kopia.io/docs/repositories/#backblaze-b2)

* [Register](https://www.backblaze.com/sign-up/s3).
* Create a new bucket for kopia repository.
  * note **the bucket name**
* Add a new application key with the access enabled to the new bucket.<br>
  After filling the info the site one time shows `applicationKey`
  * note **the keyID**
  * note **the applicationKey**
* in Kopia add new repository `Backblaze b2` fill in the required information:
  Bucket Name, KeyID and the Key.
* Set global policy.
  * Recommend setting compression, `zstd-fastest`.
  * Set schedule.
  * Retention rules.
* Pick what to backup.
* Done.

In few minutes one can have reliable encrypted cloud backup,
that deduplicates and compresses the data.<br>

**Save the repo password, plus all the info used!**

Might be worth to check bucket settings, [Lifecycle](https://www.backblaze.com/docs/cloud-storage-lifecycle-rules).
I think it should be set to `Keep only the last version of the file`

To restore files go in to Snapshots > Time > Start time > Mount as Local Filesystem.<br>
The snapshot will be mounted as `Y:`

### cli

For cli just follow [the official documentation.](https://kopia.io/docs/repositories/#backblaze-b2)
The example of commands:<br>

* `kopia repository create b2 --bucket=rakanishu --key-id=001496285081a7e0000000003 --key=K0016L8FAMRp/F+6ckbXIYpP0UgTky0 --password aaa`
* `kopia repository connect b2 --bucket=rakanishu --key-id=001496285081a7e0000000003 --key=K0016L8FAMRp/F+6ckbXIYpP0UgTky0 --password aaa`

The backup script contains example commands, just commented out.


---
---
