# Vaultwarden in docker

###### guide-by-example

![logo](https://i.imgur.com/de07I05.png)

# Purpose & Overview

Password manager. 

* [Github](https://github.com/dani-garcia/vaultwarden)
* [DockerHub](https://hub.docker.com/r/vaultwarden/server)
* [Bitwarden](https://bitwarden.com/)

Vaultwarden is a an alternative implementation of Bitwarden server,
which is a modern, popular, open source, password manager
with wide cross platform support.

But the official Bitwarden server is a bit over-engineered,
requiring Microsoft SQL server among other things,
which makes it not an ideal fit for smaller deployments.<br>
So here's where Vaultwarden by Daniel García comes in.</br>
It is a Bitwarden API implementation written in Rust.
It's very resource efficient, uses about 10MB of RAM,
and close to no CPU.</br>
Webapp part is build using Rocket, a web framework for Rust,
and user data are stored in a simple sqlite database file.

All the client apps are still official, coming from Bitwarden,
only the server is a different implementation.

![interface-pic](https://i.imgur.com/5LxEUsA.png)

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── vaultwarden/
            ├── 🗁 vaultwarden_data/
            ├── 🗋 .env
            ├── 🗋 docker-compose.yml
            └── 🗋 vaultwarden-backup-script.sh
```

* `vaultwarden_data/` - a directory storing vaultwarden's data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the container
* `bitwarden-backup-script.sh` - a backup script, to be run daily

Only the files are required. The directories are created on the first run.

# docker-compose
  
[Documentation](https://github.com/dani-garcia/vaultwarden/wiki/Using-Docker-Compose) on compose.

`docker-compose.yml`

```yml
services:

  vaultwarden:
    image: vaultwarden/server
    container_name: vaultwarden
    hostname: vaultwarden
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./vaultwarden_data/:/data/
    expose:
      - 80:80
      - 3012:3012

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true
```

`.env`
```bash
# GENERAL
DOCKER_MY_NETWORK=caddy_net
TZ=Europe/Bratislava

# BITWARDEN
DOMAIN=https://vault.example.com
ADMIN_TOKEN=zzYdLo1TM4MYzQ948oOVZ69IF4fABSrZMpk9
SIGNUPS_ALLOWED=false
WEBSOCKET_ENABLED=true

# USING SENDINBLUE FOR SENDING EMAILS
SMTP_SECURITY=starttls
SMTP_HOST=smtp-relay.sendinblue.com
SMTP_PORT=587
SMTP_FROM=admin@example.com
SMTP_USERNAME=<registration-email@gmail.com>
SMTP_PASSWORD=<sendinblue-smtp-key-goes-here>
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

`DOMAIN` and `SMTP_` stuff in the `.env` file must be set correctly for
email registration to work.<br>
`ADMIN_TOKEN` should really be changed to something else than whats up there.

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>
Vaultwarden has a very good documentation on [reverse proxy.](https://github.com/dani-garcia/bitwarden_rs/wiki/Proxy-examples)

`Caddyfile`
```php
vault.{$MY_DOMAIN} {
  encode gzip

  # Uncomment to improve security (WARNING: only use if you understand the implications!)
  # If you want to use FIDO2 WebAuthn, set X-Frame-Options to "SAMEORIGIN" or the Browser will block those requests
  header {
       # Enable HTTP Strict Transport Security (HSTS)
       Strict-Transport-Security "max-age=31536000;"
       # Enable cross-site filter (XSS) and tell browser to block detected attacks
       X-XSS-Protection "1; mode=block"
       # Disallow the site to be rendered within a frame (clickjacking protection)
       X-Frame-Options "DENY"
       # Prevent search engines from indexing (optional)
       X-Robots-Tag "none"
       # Server name removing
       -Server
  }

  # Notifications redirected to the websockets server
  reverse_proxy /notifications/hub vaultwarden:3012

  # Proxy everything else to Rocket
  reverse_proxy vaultwarden:80 {
       # Send the true remote IP to Rocket, so that vaultwarden can put this in the
       # log, so that fail2ban can ban the correct IP.
       header_up X-Real-IP {remote_host}
  }
}
```

# Forward port 3012 TCP on your router

[WebSocket](https://youtu.be/2Nt-ZrNP22A) protocol is used for communication
so that all web based clients, including desktop app,
can immediately sync when a change happens on the server.

* environment variable `WEBSOCKET_ENABLED=true` needs to be set in the `.env` file</br>
* reverse proxy needs to route `/notifications/hub` to port 3012</br>
* your router/firewall needs to **forward port 3012** to the docker host,
same as port 80 and 443 are forwarded

To test if websocket works, have the desktop app open
and make changes through browser extension, or through the website.
Changes should immediately appear in the desktop app.<br> If it's not working,
you need to manually sync for changes to appear.

**Push notifications** are not working, and it's unlikely to change.
[Github issue](https://github.com/dani-garcia/bitwarden_rs/issues/126).</br>
The purpose of [Push notifications](https://www.youtube.com/watch?v=8D1NAezC-Dk)
is the same as WebSocket notifications, to tell the clients that a change
happened on the server so that they are synced immediately.
But they are for apps on mobile devices and it would likely take releasing and
maintaining own vaultwarden version of Android/iOS mobile apps
to have this feature working.</br>
So you better manually sync before making changes.

# First run

![admin_logon](https://i.imgur.com/vGdJQG0.png)

Login at `https://vault.example.com/admin` using
`ADMIN_TOKEN` from the `.env` file<br>
From the admin interface test email can be send, and new users can be invited.

![users_invite](https://i.imgur.com/K2oA1nA.png)

# Update

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

It is **strongly recommended** to now add current **tags** to the images in the compose.<br>
Tags will allow you to easily return to a working state if an update goes wrong.

# Backup and restore

#### Backup

Using [kopia](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/kopia_backup)
or [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
to make daily snapshot of the entire docker directory.
  
#### Restore

* down the containers `docker-compose down`</br>
* delete/move/rename the entire project directory</br>
* from the backups copy back the entire project directory</br>
* start the containers `docker-compose up -d`

# Backup of just user data

Users data daily export using the
[official procedure.](https://github.com/dani-garcia/vaultwarden/wiki/Backing-up-your-vault)</br>
For vaultwarden it means sqlite database dump and backing up `attachments` directory.</br>

Daily kopia/borg backup run takes care of backing up the directories.
So only database dump is needed and done with the script.</br>
The created backup sqlite3 file is overwritten on every run of the script,
but that's ok since kopia/borg are keeping daily snapshots.

#### Create a backup script

The backup script requires sqlite/sqlite3 package to be installed **on the host**.<br>
The backup script must be placed on the host with the bind mounted
`vaultwarden_data` directory next to it.

`vaultwarden-backup-script.sh`
```bash
#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

# CREATE SQLITE BACKUP
sqlite3 ./vaultwarden_data/db.sqlite3 "VACUUM INTO './vaultwarden_data/BACKUP.vaultwarden.db.sqlite3'"
```

the script must be **executable** - `chmod +x vaultwarden-backup-script.sh`

#### Cronjob

Running on the host

* `su` - switch to root
* `crontab -e` - add new cron job</br>
* `15 01 * * * /home/bastard/docker/vaultwarden/vaultwarden-backup-script.sh`</br>
  runs it every night [at 01:15](https://crontab.guru/#15_01_*_*_*) 
* `crontab -l` - list cronjobs to check

# Restore the user data

Assuming clean start.

* start the vaultwarden container: `docker-compose up -d`
* let it run so it creates its file structure
* down the container `docker-compose down`
* in `vaultwarden/vaultwarden_data/`</br>
  delete `db.sqlite3-wal` if it exists<br>
  delete `db.sqlite3`<br>
  place backup there `BACKUP.vaultwarden.db.sqlite3`</br>
  rename it to `db.sqlite3`<br>
  replace `attachments` directory with the one from the backups<br>
  additionally `sends` and `config.jso` can also be copied from backups
* start the container `docker-compose up -d`

Again, the above steps are based on the 
[official procedure.](https://github.com/dani-garcia/vaultwarden/wiki/Backing-up-your-vault#backing-up-data).
Read it for more info whats where as the documentation is really excelent.
