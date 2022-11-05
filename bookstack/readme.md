# Bookstack in docker

###### guide-by-example

![logo](https://i.imgur.com/qDXwqaU.png)

# Purpose & Overview

Documentation and notes.

* [Official site](https://www.bookstackapp.com/)
* [Github](https://github.com/BookStackApp/BookStack)
* [DockerHub](https://hub.docker.com/r/linuxserver/bookstack)

BookStack is a modern, open source, good looking wiki platform
for storing and organizing information.

Written in PHP, with MySQL database for the user data.</br>
There is no official Dockerhub image so the one maintained by
[linuxserver.io](https://www.linuxserver.io/) is used,
which uses nginx as a web server.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── bookstack/
            ├── bookstack-data/
            ├── bookstack-db-data/
            ├── .env
            ├── docker-compose.yml
            └── bookstack-backup-script.sh
```

* `bookstack-data/` - a directory where bookstack will store its web app data
* `bookstack-db-data/` - a directory where bookstack will store its MySQL database data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers
* `bookstack-backup-script.sh` - a backup script if you want it

You only need to provide the files.</br>
The directories are created by docker compose on the first run.

# docker-compose

Dockerhub linuxserver/bookstack 
[example compose.](https://hub.docker.com/r/linuxserver/bookstack)

`docker-compose.yml`
```yml
version: "2"
services:

  bookstack-db:
    image: linuxserver/mariadb
    container_name: bookstack-db
    hostname: bookstack-db
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./bookstack-db-data:/config

  bookstack:
    image: linuxserver/bookstack
    container_name: bookstack
    hostname: bookstack
    restart: unless-stopped
    env_file: .env
    depends_on:
      - bookstack-db
    volumes:
      - ./bookstack-data:/config

networks:
  default:
    external:
      name: $DOCKER_MY_NETWORK
```

`.env`
```bash
# GENERAL
MY_DOMAIN=example.com
DOCKER_MY_NETWORK=caddy_net
TZ=Europe/Bratislava

#LINUXSERVER.IO
PUID=1000
PGID=1000

# BOOKSTACK-MARIADB
MYSQL_ROOT_PASSWORD=bookstack
MYSQL_DATABASE=bookstack
MYSQL_USER=bookstack
MYSQL_PASSWORD=bookstack

# BOOKSTACK
APP_URL=https://book.example.com
DB_HOST=bookstack-db
DB_USER=bookstack
DB_PASS=bookstack
DB_DATABASE=bookstack

# USING SENDGRID FOR SENDING EMAILS
MAIL_ENCRYPTION=SSL
MAIL_DRIVER=smtp
MAIL_HOST=smtp.sendgrid.net
MAIL_PORT=465
MAIL_FROM=book@example.com
MAIL_USERNAME=apikey
SMTP_PASSWORD=<sendgrid-api-key-goes-here>
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
book.{$MY_DOMAIN} {
    reverse_proxy bookstack:80
}
```

# First run

Default login: `admin@admin.com` // `password`

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
