# Bookstack in docker

###### guide by example

![logo](https://i.imgur.com/qDXwqaU.png)

# Purpose

Documentation and notes.

* [Official site](https://www.bookstackapp.com/)
* [Github](https://github.com/BookStackApp/BookStack)
* [DockerHub](https://hub.docker.com/r/linuxserver/bookstack)

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
      name: $DEFAULT_NETWORK
```

`.env`
```bash
# GENERAL
MY_DOMAIN=blabla.org
DEFAULT_NETWORK=caddy_net
TZ=Europe/Prague

#LINUXSERVER.IO
PUID=1000
PGID=1000

# BOOKSTACK-MARIADB
MYSQL_ROOT_PASSWORD=bookstack
MYSQL_DATABASE=bookstack
MYSQL_USER=bookstack
MYSQL_PASSWORD=bookstack

# BOOKSTACK
DB_HOST=bookstack-db
DB_USER=bookstack
DB_PASS=bookstack
DB_DATABASE=bookstack

# USING SENDGRID FOR SENDING EMAILS
APP_URL=https://book.blabla.org
MAIL_DRIVER=smtp
MAIL_HOST=smtp.sendgrid.net
MAIL_PORT=465
MAIL_FROM=book@blabla.org
MAIL_USERNAME=apikey
MAIL_PASSWORD=SG.2FA24asaddasdasdasdsadasdasdassadDEMBzuh9e43
MAIL_ENCRYPTION=SSL
```

**All containers must be on the same network**.</br>
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

---

![interface-pic](https://i.imgur.com/cN1GUZw.png)

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
    down the bookstack containers `docker-compose down`</br>
    delete the entire bookstack directory</br>
    from the backup copy back the bookstack directortory</br>
    start the container `docker-compose up -d`

# Backup of just user data

User-data daily export using the [official procedure.](https://www.bookstackapp.com/docs/admin/backup-restore/)</br>
For bookstack it means database dump and backing up several directories
containing user uploaded files.

Daily run of [BorgBackup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
takes care of backing up the directories.
So only database dump is needed.
The created database backup sql file is overwriten on every run of the script,
but that's ok since BorgBackup is making daily snapshots.

* **create a backup script**</br>
    placed inside `bookstack` directory on the host

    `bookstack-backup-script.sh`
    ```bash
    #!/bin/bash

    # CREATE DATABASE DUMP, bash -c '...' IS USED OTHERWISE OUTPUT > WOULD TRY TO GO TO THE HOST
    docker container exec bookstack-db bash -c 'mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $MYSQL_DIR/BACKUP.bookstack.database.sql'
    ```

    the script must be **executabe** - `chmod +x bookstack-backup-script.sh`

* **cronjob** on the host</br>
  `crontab -e` - add new cron job</br>
  `0 2 * * * /home/bastard/docker/bookstack/bookstack-backup-script.sh` - run it [at 02:00](https://crontab.guru/#0_2_*_*_*)</br>
  `crontab -l` - list cronjobs

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
