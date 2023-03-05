a# Mealie in docker

###### guide-by-example

![logo](https://i.imgur.com/qDXwqaU.png)

# Purpose & Overview

Documentation and notes.

* [Official site](https://www.bookstackapp.com/)
* [Github](https://github.com/BookStackApp/BookStack)
* [DockerHub](https://hub.docker.com/r/linuxserver/bookstack)

BookStack is a modern, open source, good looking wiki platform
for storing and organizing information.

Written in PHP, using Laravel framework, with MySQL database for the user data.</br>
There is no official Dockerhub image so the one maintained by
[linuxserver.io](https://www.linuxserver.io/) is used,
which uses nginx as a web server.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── bookstack/
            ├── 🗁 bookstack_data/
            ├── 🗁 bookstack_db_data/
            ├── 🗋 .env
            ├── 🗋 docker-compose.yml
            └── 🗋 bookstack-backup-script.sh
```

* `bookstack_data/` - a directory with bookstacks web app data
* `bookstack_db_data/` - a directory with database data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers
* `bookstack-backup-script.sh` - a backup script, to be run daily

Only the files are required. The directories are created on the first run.

# docker-compose

Dockerhub linuxserver/bookstack 
[example compose.](https://hub.docker.com/r/linuxserver/bookstack)

`docker-compose.yml`
```yml
services:

  mealie:
    image: hkotel/mealie
    container_name: mealie
    hostname: mealie
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./mealie_data:/app/data
    expose:
      - 80:80

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


# MEALIE
PUID=1000
PGID=1000
RECIPE_PUBLIC=true
RECIPE_SHOW_NUTRITION=true
RECIPE_SHOW_ASSETS=true
RECIPE_LANDSCAPE_VIEW=true
RECIPE_DISABLE_COMMENTS=false
RECIPE_DISABLE_AMOUNT=false

# USING SENDINBLUE FOR SENDING EMAILS
MAIL_DRIVER=smtp
MAIL_ENCRYPTION=tls
MAIL_HOST=smtp-relay.sendinblue.com
MAIL_PORT=587
MAIL_FROM=book@example.com
MAIL_USERNAME=<registration-email@gmail.com>
MAIL_PASSWORD=<sendinblue-smtp-key-goes-here>
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

`APP_URL` in the `.env` **must be set** for bookstack to work.<br>
`MAIL_` stuff must be set for password reset and new registrations.

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```php
book.{$MY_DOMAIN} {
    reverse_proxy bookstack:80
}
```

# First run

Default login: `admin@admin.com` // `password`

---

![interface-pic](https://i.imgur.com/cN1GUZw.png)

# Trouble shooting

* It did not start.<br>
  Ctrl+f in `.env` file for word `example` to be replaced with actual domain
  name. `APP_URL` has to be set correctly for bookstack to work.
* After update cant see edit tools.<br>
  Clear browsers cookies/cache.
* The test email button in preferences throws error.<br>
  Exec in to the container and `printenv` to see.
  Check [mail.php](https://github.com/BookStackApp/BookStack/blob/development/app/Config/mail.php)
  to see exact `MAIL_` env variables names and default values.
  Test in Thunderbird your smtp server working or not.

# Update

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

It is **strongly recommended** to now add current **tags** to the images in the compose.<br>
Tags will allow you to easily return to a working state if an update goes wrong.

If there was a **major version jump**, and bookstack does not work,
exec in to the app container and run php artisan migrate</br>
`docker container exec -it bookstack /bin/bash`</br>
`cd /app/www`</br>
`php artisan migrate`

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
[official procedure.](https://www.bookstackapp.com/docs/admin/backup-restore/)</br>
For bookstack it means database dump and backing up several directories
containing user uploaded files.

Daily kopia/borg backup run takes care of backing up the directories.
So only database dump is needed and done with the script.</br>
The created backup sql file is overwritten on every run of the script,
but that's ok since kopia/borg are keeping daily snapshots.

#### Backup script

Placed inside `bookstack` directory on the host

`bookstack-backup-script.sh`
```bash
#!/bin/bash

# CREATE DATABASE DUMP, bash -c '...' IS USED OTHERWISE OUTPUT > WOULD TRY TO GO TO THE HOST
docker container exec bookstack-db bash -c 'mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $MYSQL_DIR/BACKUP.bookstack.database.sql'
```

The script must be **executable** - `chmod +x bookstack-backup-script.sh`

#### Cronjob - scheduled backup

Running on the host

* `su` - switch to root
* `crontab -e` - add new cron job</br>
* `0 22 * * * /home/bastard/docker/bookstack/bookstack-backup-script.sh`</br>
  runs it every day [at 22:00](https://crontab.guru/#0_22_*_*_*) 
* `crontab -l` - list cronjobs to check

# Restore the user data

Assuming clean start and latest images.<br>
Will need `BACKUP.bookstack.database.sql` and content of `bookstack_data/www/`<br>
Note that database restore must happen before bookstack app is first run.

* start only the database container: `docker-compose up -d bookstack-db`
* copy `BACKUP.bookstack.database.sql` in `bookstack/bookstack_db_data/`
* restore the database inside the container</br>
  `docker container exec --workdir /config bookstack-db bash -c 'mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < BACKUP.bookstack.database.sql'`
* now start the app container: `docker-compose up -d`
* let it run so it creates its file structure
* down the containers `docker-compose down`
* in `bookstack/bookstack_data/www/`</br>
  replace directories `files`,`images`,`uploads` and the file `.env`</br>
  with the ones from the BorgBackup repository 
* start the containers: `docker-compose up -d`
* if there was a major version jump, exec in to the app container and run `php artisan migrate`</br>
  `docker container exec -it bookstack /bin/bash`</br>
  `cd /app/www`</br>
  `php artisan migrate`

Again, the above steps are based on the 
[official procedure](https://www.bookstackapp.com/docs/admin/backup-restore/)
at the time of writing this.
