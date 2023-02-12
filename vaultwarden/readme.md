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
DOMAIN=https://passwd.example.com
ADMIN_TOKEN=YdLo1TM4MYzQ948oOVZ69IF4fABSrZMpk9
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

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>
Vaultwarden's documentation has a 
[section on reverse proxy.](https://github.com/dani-garcia/bitwarden_rs/wiki/Proxy-examples)

`Caddyfile`
```go
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

  # Uncomment to allow access to the admin interface only from local networks
  @insecureadmin {
    not remote_ip 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8
    path /admin*
  }
  redir @insecureadmin /

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

[WebSocket](https://youtu.be/2Nt-ZrNP22A) protocol is used for notifications
so that all web based clients, including desktop app,
can immediately sync when a change happens on the server.

* environment variable `WEBSOCKET_ENABLED=true` needs to be set in the `.env` file</br>
* reverse proxy needs to route `/notifications/hub` to port 3012</br>
* your router/firewall needs to **forward port 3012** to the docker host,
same as port 80 and 443 are forwarded

To test if websocket works, have the desktop app open
and make changes through browser extension, or through the website.
Changes should immediately appear in the desktop app. If it's not working,
you need to manually sync for changes to appear.
 
# Extra info

**Bitwarden can be managed** at `<url>/admin` and entering `ADMIN_TOKEN`
set in the `.env` file. Especially if sign ups are disabled it is the only way
to invite users.

**Push notifications** are not working at this moment.
[Github issue](https://github.com/dani-garcia/bitwarden_rs/issues/126).</br>
The purpose of [Push notifications](https://www.youtube.com/watch?v=8D1NAezC-Dk)
is the same as WebSocket notifications, to tell the clients that a change
happened on the server so that they are synced immediately.
But they are for apps on mobile devices and it would likely take releasing and
maintaining own bitwarden_rs version of the Android/iOS mobile apps
to have them working.</br>
So you better manually sync before making changes.

---

![interface-pic](https://i.imgur.com/5LxEUsA.png)

# Update

[Watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower)
updates the image automatically.

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

# Backup and restore

#### Backup

Using [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the entire directory.
  
#### Restore

* down the bitwarden container `docker-compose down`</br>
* delete the entire bitwarden directory</br>
* from the backup copy back the bitwarden directory</br>
* start the container `docker-compose up -d`

# Backup of just user data

Users data daily export using the
[official procedure.](https://github.com/dani-garcia/bitwarden_rs/wiki/Backing-up-your-vault)</br>
For bitwarden_rs it means sqlite database dump and backing up `attachments` directory.</br>

Daily [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup) run
takes care of backing up the directory.
So only database dump is needed.</br>
The created backup sqlite3 file is overwritten on every run of the script,
but that's ok since borg is making daily snapshots.

#### Create a backup script

Placed inside `bitwarden` directory on the host.

`bitwarden-backup-script.sh`
```bash
#!/bin/bash

# CREATE SQLITE BACKUP
docker container exec bitwarden sqlite3 /data/db.sqlite3 ".backup '/data/BACKUP.bitwarden.db.sqlite3'"
```

the script must be **executable** - `chmod +x bitwarden-backup-script.sh`

#### Cronjob

Running on the host, so that the script will be periodically run.

* `su` - switch to root
* `crontab -e` - add new cron job</br>
* `0 21 * * * /home/bastard/docker/bitwarden/bitwarden-backup-script.sh`</br>
  runs it every day [at 21:00](https://crontab.guru/#0_21_*_*_*) 
* `crontab -l` - list cronjobs to check

# Restore the user data

Assuming clean start.

* start the bitwarden container: `docker-compose up -d`
* let it run so it creates its file structure
* down the container `docker-compose down`
* in `bitwarden/bitwarden-data/`</br>
  replace `db.sqlite3` with the backup one `BACKUP.bitwarden.db.sqlite3`</br>
  replace `attachments` directory with the one from the borg repository 
* start the container `docker-compose up -d`

Again, the above steps are based on the 
[official procedure.](https://github.com/dani-garcia/bitwarden_rs/wiki/Backing-up-your-vault)
