# Snipe-IT in docker

###### guide-by-example

![logo](https://i.imgur.com/NEABBL7.png)

# Purpose & Overview

IT inventory managment tool.

* [Official site](https://snipeitapp.com/)
* [Github](https://github.com/snipe/snipe-it)
* [DockerHub](https://hub.docker.com/r/snipe/snipe-it/)

Snipe-IT is a modern, open source, go-to asset managment tool with LDAP integration.</br>
Written in PHP, using Laravel framework.
This setup is using mariadb database for storing the data.</br>
Dockerhub image maintained by
[linuxserver.io](https://docs.linuxserver.io/images/docker-snipe-it)
is used.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── snipeit/
            ├── config/
            ├── snipeit-db/
            ├── .env
            └── docker-compose.yml
```

* `config/` - a directory where snipe-it will store its web server stuff
* `snipeit-db/` - a directory where snipeit will store its database data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the files.</br>
The directories are created by docker compose on the first run.

# docker-compose

`docker-compose.yml`
```yml
services:
  snipeit-db:
    image: mariadb
    container_name: snipeit-db
    hostname: snipeit-db
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./snipeit-db:/var/lib/mysql

  snipeit:
    image: linuxserver/snipe-it:latest
    container_name: snipeit
    hostname: snipeit
    restart: unless-stopped
    env_file: .env
    depends_on:
      - snipeit-db
    volumes:
      - ./config:/config

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

#LINUXSERVER.IO mariadb
PUID=1000
PGID=1000
MYSQL_ROOT_PASSWORD=snipeit
MYSQL_DATABASE=snipeit
MYSQL_USER=snipeit
MYSQL_PASSWORD=snipeit

#LINUXSERVER.IO Snipe-IT
APP_URL=https://snipe.example.com
MYSQL_PORT_3306_TCP_ADDR=snipeit-db
MYSQL_PORT_3306_TCP_PORT=3306
MYSQL_DATABASE=snipeit
MYSQL_USER=snipeit
MYSQL_PASSWORD=snipeit
APP_TRUSTED_PROXIES=*

#EMAIL
MAIL_PORT_587_TCP_ADDR=smtp-relay.sendinblue.com
MAIL_PORT_587_TCP_PORT=587
MAIL_ENV_FROM_ADDR=noreply@example.com
MAIL_ENV_FROM_NAME=snipe-it admin
MAIL_ENV_ENCRYPTION=tls
MAIL_ENV_USERNAME=your_email@registrated-on-sendinblue.com
MAIL_ENV_PASSWORD=your_sendinblue_smtp_key_value
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
snipe.{$MY_DOMAIN} {
  encode gzip
  reverse_proxy snipeit:443 {
    transport http {
      tls
      tls_insecure_skip_verify
    }
  }
}
```

# First run


![interface-pic](https://i.imgur.com/wtwb4hn.png)

---


# Trouble shooting



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

* down the snipeit containers `docker-compose down`</br>
* delete the entire snipeit directory</br>
* from the backup copy restore the snipeit directory</br>
* start the containers `docker-compose up -d`

# Backup of just user data

Users data daily export using the
[official procedure.](https://www.snipeitapp.com/docs/admin/backup-restore/)</br>
For snipeit it means database dump and backing up several directories
containing user uploaded files.

Daily [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup) run
takes care of backing up the directories.
So only database dump is needed.</br>
The created backup sqlite3 file is overwritten on every run of the script,
but that's ok since borg is making daily snapshots.

#### Create a backup script

Placed inside `snipeit` directory on the host

`snipeit-backup-script.sh`
```bash
#!/bin/bash

# CREATE DATABASE DUMP, bash -c '...' IS USED OTHERWISE OUTPUT > WOULD TRY TO GO TO THE HOST
docker container exec snipeit-db bash -c 'mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $MYSQL_DIR/BACKUP.snipeit.database.sql'
```

the script must be **executable** - `chmod +x snipeit-backup-script.sh`

#### Cronjob

Running on the host, so that the script will be periodically run.

* `su` - switch to root
* `crontab -e` - add new cron job</br>
* `0 22 * * * /home/bastard/docker/snipeit/snipeit-backup-script.sh`</br>
  runs it every day [at 22:00](https://crontab.guru/#0_22_*_*_*) 
* `crontab -l` - list cronjobs to check

# Restore the user data

Assuming clean start, first restore the database before running the app container.

* start only the database container: `docker-compose up -d snipeit-db`
* copy `BACKUP.snipeit.database.sql` in `snipeit/snipeit-db-data/`
* restore the database inside the container</br>
  `docker container exec --workdir /config snipeit-db bash -c 'mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < BACKUP.snipeit.database.sql'`
* now start the app container: `docker-compose up -d`
* let it run so it creates its file structure
* down the containers `docker-compose down`
* in `snipeit/snipeit-data/www/`</br>
  replace directories `files`,`images`,`uploads` and the file `.env`</br>
  with the ones from the BorgBackup repository 
* start the containers: `docker-compose up -d`
* if there was a major version jump, exec in to the app container and run `php artisan migrate`</br>
  `docker container exec -it snipeit /bin/bash`</br>
  `cd /var/www/html/`</br>
  `php artisan migrate`

Again, the above steps are based on the 
[official procedure.](https://www.snipeitapp.com/docs/admin/backup-restore/)
