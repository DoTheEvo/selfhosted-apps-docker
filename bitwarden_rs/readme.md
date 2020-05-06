# Bitwarden_rs in docker

###### guide by example

![logo](https://i.imgur.com/tT3FQLJ.png)

# Purpose & Overview

Password manager. 

* [Official site](https://bitwarden.com/)
* [Github](https://github.com/dani-garcia/bitwarden_rs)
* [DockerHub](https://hub.docker.com/r/bitwardenrs/server)

Bitwarden is a modern popular open source password manager
with wide cross platform support.

But the official Bitwarden server is not really fit for smaller deployment and
requires Microsoft SQL server among other things.</br>
So here is where Bitwarden_rs by Daniel García comes in.</br>
It is a Bitwarden API implementation written in Rust.
It's very resource efficient, uses about 10MB of RAM,
and close to no CPU.</br>
It's build using Rocket a web framework for Rust
and user data are stored in a simple sqlite database file.

All the client apps are still officials coming from bitwarden,
only the server is a different implementation.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── bitwarden/
            ├── bitwarden-data/
            ├── .env
            ├── docker-compose.yml
            └── bitwarden-backup-script.sh
```

* `bitwarden-data/` - a directory where bitwarden will store its database and other data
* `.env` - a file containing environmental variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to build bitwarden container
* `bitwarden-backup-script.sh` - a backup script if you want it

You only need to provide the files.</br>
The directory is created by docker compose on the first run.

# docker-compose
  
[Documentation](https://github.com/dani-garcia/bitwarden_rs/wiki/Using-Docker-Compose) on compose.

`docker-compose.yml`

```yml
version: "3"
services:

  bitwarden:
    image: bitwardenrs/server
    container_name: bitwarden
    hostname: bitwarden
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./bitwarden-data/:/data/

networks:
  default:
    external:
      name: $DEFAULT_NETWORK
```

`.env`
```bash
# GENERAL
MY_DOMAIN=blabla.org
DEFAULT_NETWORK=caddy_net
TZ=Europe/Bratislava

# BITWARDEN
ADMIN_TOKEN=YdLo1TM4MYEQ948GOVZ29IF4fABSrZMpk9
SIGNUPS_ALLOWED=false
WEBSOCKET_ENABLED=true

# USING SENDGRID FOR SENDING EMAILS
DOMAIN=https://passwd.blabla.org
SMTP_SSL=true
SMTP_EXPLICIT_TLS=true
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=465
SMTP_USERNAME=apikey
SMTP_PASSWORD=SG.MOQQegA3bgfodRN4IG2Wqwe.s23Ld4odqhOQQegf4466A4
SMTP_FROM=admin@blabla.org
```

**All containers must be on the same network**.</br>
If one does not exist yet: `docker network create caddy_net`

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>
Bitwarden_rs documentation has a 
[section on reverse proxy.](https://github.com/dani-garcia/bitwarden_rs/wiki/Proxy-examples)

`Caddyfile`
```
passwd.{$MY_DOMAIN} {
    header / {
       X-XSS-Protection "1; mode=block"
       X-Frame-Options "DENY"
       X-Robots-Tag "none"
       -Server
    }
    encode gzip
    reverse_proxy /notifications/hub/negotiate bitwarden:80
    reverse_proxy /notifications/hub bitwarden:3012
    reverse_proxy bitwarden:80
}
```

# Forward port 3012 TCP on your router

[WebSocket](https://youtu.be/2Nt-ZrNP22A) protocol is used for notifications,
so that all web based clients can immediatly sync when a change happens on the server.

* Enviromental variable `WEBSOCKET_ENABLED=true` needs to be set.</br>
* Reverse proxy needs to route `/notifications/hub` to port 3012.</br>
* Router needs to **forward port 3012** to docker host,
same as port 80 and 443 are forwarded.

To test if websocket works, have the desktop app open
and make changes through browser extension, or through the website.
Changes should immediatly appear in the desktop app. If it's not working,
you need to manually sync for changes to appear.
 
# Extra info

**bitwarden can be managed** at `<url>/admin` and entering `ADMIN_TOKEN`
set in the `.env` file. Especially if signups are disabled it is the only way
to invite users.

**push notifications**

---

![interface-pic](https://i.imgur.com/5LxEUsA.png)

# Update

  * [watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower) updates the image automaticly

  * manual image update</br>
    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`

# Backup and restore

  * **backup** using [BorgBackup setup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
  that makes daily snapshot of the entire directory
    
  * **restore**</br>
    down the bitwarden container `docker-compose down`</br>
    delete the entire bitwarden directory</br>
    from the backup copy back the bitwarden directortory</br>
    start the container `docker-compose up -d`

# Backup of just user data

Users data daily export using the [official procedure.](https://github.com/dani-garcia/bitwarden_rs/wiki/Backing-up-your-vault)</br>
For bitwarden_rs it means sqlite database dump and backing up `attachments` directory.</br>

Daily run of [BorgBackup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
takes care of backing up the directory.
So only database dump is needed.
The created backup sqlite3 file is overwriten on every run of the script,
but that's ok since BorgBackup is making daily snapshots.

* **create a backup script**</br>
    placed inside `bitwarden` directory on the host
    
    `bitwarden-backup-script.sh`
    ```
    #!/bin/bash

    # CREATE SQLITE BACKUP
    docker container exec bitwarden sqlite3 /data/db.sqlite3 ".backup '/data/BACKUP.bitwarden.db.sqlite3'"
    ```

    the script must be **executabe** - `chmod +x bitwarden-backup-script.sh`

* **cronjob** on the host</br>
  `crontab -e` - add new cron job</br>
  `0 2 * * * /home/bastard/docker/bitwarden/bitwarden-backup-script.sh` - run it [at 02:00](https://crontab.guru/#0_2_*_*_*)</br>
  `crontab -l` - list cronjobs

# Restore the user data

  Assuming clean start.

  * start the bitwarden container: `docker-compose up -d`
  * let it run so it creates its file structure
  * down the container `docker-compose down`
  * in `bitwarden/bitwarden-data/`</br>
    replace `db.sqlite3` with the backup one `BACKUP.bitwarden.db.sqlite3`</br>
    replace `attachments` directory with the one from the BorgBackup repository 
  * start the container `docker-compose up -d`

