# Rustdesk in docker

###### guide-by-example

![logo](https://i.imgur.com/ImsIffW.png)

# Purpose & Overview

Remote desktop application. 

* [Official site](https://rustdesk.com/)
* [Github](https://github.com/rustdesk/rustdesk)
* [DockerHub](https://hub.docker.com/r/rustdesk/rustdesk-server)

Rustdesk is a young opensource replacement for TeamViewer or Anydesk.
The major thing is that it does NAT punching, 
and lets you host all the infrastructure for it to function.

Written in rust(gasp), with Dart and Flutter framework for client side.</br>

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── rustdesk/
            ├── data/
            ├── .env
            └── docker-compose.yml
```

* `data/` - relay server
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the files.</br>
The directories are created by docker compose on the first run.

# docker-compose

Using edited version of [S6-overlay based images.](https://github.com/rustdesk/rustdesk-server#s6-overlay-based-images)

`docker-compose.yml`
```yml
services:
  rustdesk:
    image: rustdesk/rustdesk-server-s6:latest
    container_name: rustdesk
    hostname: rustdesk
    restart: unless-stopped
    env_file: .env
    ports:
      - 21115:21115
      - 21116:21116
      - 21116:21116/udp
      - 21117:21117
      - 21118:21118
      - 21119:21119
    volumes:
      - ./data:/data

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true
```

`.env`
```bash
# GENERAL
MY_DOMAIN=example.com
DOCKER_MY_NETWORK=caddy_net
TZ=Europe/Bratislava

# RUSTDESK
RELAY=rust.example.com:21117
ENCRYPTED_ONLY=1"
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

# Port forwarding

ports 21115 - 21119 needs to be open
port 21116 open as tcp and udp

# First run
.....
....
...
..
.

---

![interface-pic](https://i.imgur.com/cN1GUZw.png)

# Trouble shooting

If after update you cant see edit tools. Clear cookies.

# Update

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

# Backup and restore

#### Backup

Using [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the entire directory.
  
#### Restore

* down the bookstack containers `docker-compose down`</br>
* delete the entire bookstack directory</br>
* from the backup copy back the bookstack directory</br>
* start the containers `docker-compose up -d`

# Backup of just user data

Users data daily export using the
[official procedure.](https://www.bookstackapp.com/docs/admin/backup-restore/)</br>
For bookstack it means database dump and backing up several directories
containing user uploaded files.

Daily [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup) run
takes care of backing up the directories.
So only database dump is needed.</br>
The created backup sqlite3 file is overwritten on every run of the script,
but that's ok since borg is making daily snapshots.

#### Create a backup script

Placed inside `bookstack` directory on the host

`bookstack-backup-script.sh`
```bash
#!/bin/bash

# CREATE DATABASE DUMP, bash -c '...' IS USED OTHERWISE OUTPUT > WOULD TRY TO GO TO THE HOST
docker container exec bookstack-db bash -c 'mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $MYSQL_DIR/BACKUP.bookstack.database.sql'
```

the script must be **executable** - `chmod +x bookstack-backup-script.sh`

#### Cronjob

Running on the host, so that the script will be periodically run.

* `su` - switch to root
* `crontab -e` - add new cron job</br>
* `0 22 * * * /home/bastard/docker/bookstack/bookstack-backup-script.sh`</br>
  runs it every day [at 22:00](https://crontab.guru/#0_22_*_*_*) 
* `crontab -l` - list cronjobs to check

# Restore the user data

Assuming clean start, first restore the database before running the app container.

* start only the database container: `docker-compose up -d bookstack-db`
* copy `BACKUP.bookstack.database.sql` in `bookstack/bookstack-db-data/`
* restore the database inside the container</br>
  `docker container exec --workdir /config bookstack-db bash -c 'mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < BACKUP.bookstack.database.sql'`
* now start the app container: `docker-compose up -d`
* let it run so it creates its file structure
* down the containers `docker-compose down`
* in `bookstack/bookstack-data/www/`</br>
  replace directories `files`,`images`,`uploads` and the file `.env`</br>
  with the ones from the BorgBackup repository 
* start the containers: `docker-compose up -d`
* if there was a major version jump, exec in to the app container and run `php artisan migrate`</br>
  `docker container exec -it bookstack /bin/bash`</br>
  `cd /var/www/html/`</br>
  `php artisan migrate`

Again, the above steps are based on the 
[official procedure.](https://www.bookstackapp.com/docs/admin/backup-restore/)
