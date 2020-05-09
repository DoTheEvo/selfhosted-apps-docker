# Nextcloud in docker

###### guide by example

![logo](https://i.imgur.com/VXSovC9.png)

# Purpose & Overview

File share & sync.

* [Official site](https://nextcloud.com/)
* [Github](https://github.com/nextcloud/server)
* [DockerHub](https://hub.docker.com/_/nextcloud/)

Nextcloud is an open source suite of client-server software for creating
and using file hosting services with wide cross platform support.

The Nextcloud server is written in PHP and JavaScript.
For remote access it employs sabre/dav, an open-source WebDAV server.
It is designed to work with several database management systems,
including SQLite, MariaDB, MySQL, PostgreSQL.

There are many ways to deploy Nextcloud, this setup is going with the most goodies.</br>
Using [PHP-FPM](https://www.cloudways.com/blog/php-fpm-on-cloud/)
for better performance and using [Redis](https://aws.amazon.com/redis/)
for more reliable
[transactional file locking](https://docs.nextcloud.com/server/latest/admin_manual/configuration_files/files_locking_transactional.html)
and for [memory file caching](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/caching_configuration.html).

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── nextcloud/
            ├── nextcloud-data/
            ├── nextcloud-db-data/
            ├── .env
            ├── docker-compose.yml
            ├── nginx.conf
            └── nextcloud-backup-script.sh
```

* `nextcloud-data/` - a directory where nextcloud will store users data and web app data
* `nextcloud-db-data/` - a directory where nextcloud will store its database data
* `.env` - a file containing environmental variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to build the containers
* `nginx.conf` - nginx web server configuration file
* `nextcloud-backup-script.sh` - a backup script if you want it

You only need to provide the files.</br>
The directories are created by docker compose on the first run.

# docker-compose

Official examples [here](https://github.com/nextcloud/docker/tree/master/.examples/docker-compose)

Five containers to spin up

* **nextcloud-app** - nextcloud backend app that stores the files and facilitate 
  the sync and runs the apps
* **nextcloud-db** - mariadb database where files-metadata and users-metadata are stored
* **nextcloud-web** - nginx web server with fastCGI PHP-FPM support
* **nextcloud-redis** - in memory file caching
  and more reliable transactional file locking
* **nextcloud-cron** - for periodic maintenance in the background

`docker-compose.yml`
```yml
version: '3'
services:

  nextcloud-db:
    image: mariadb
    container_name: nextcloud-db
    hostname: nextcloud-db
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
    restart: unless-stopped
    volumes:
      - ./nextcloud-data-db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD
      - MYSQL_PASSWORD
      - MYSQL_DATABASE
      - MYSQL_USER

  nextcloud-redis:
    image: redis:alpine
    container_name: nextcloud-redis
    hostname: nextcloud-redis
    restart: unless-stopped

  nextcloud-app:
    image: nextcloud:fpm-alpine
    container_name: nextcloud-app
    hostname: nextcloud-app
    restart: unless-stopped
    depends_on:
      - nextcloud-db
      - nextcloud-redis
    volumes:
      - ./nextcloud-data/:/var/www/html
    environment:
      - MYSQL_HOST
      - REDIS_HOST
      - MAIL_DOMAIN
      - MAIL_FROM_ADDRESS
      - SMTP_SECURE
      - SMTP_HOST
      - SMTP_PORT
      - SMTP_NAME
      - SMTP_PASSWORD

  nextcloud-web:
    image: nginx:alpine
    container_name: nextcloud-web
    hostname: nextcloud-web
    restart: unless-stopped
    volumes:
      - ./nextcloud-data/:/var/www/html:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro

  nextcloud-cron:
    image: nextcloud:fpm-alpine
    container_name: nextcloud-cron
    hostname: nextcloud-cron
    restart: unless-stopped
    volumes:
      - ./nextcloud-data/:/var/www/html
    entrypoint: /cron.sh
    depends_on:
      - nextcloud-db
      - nextcloud-redis

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

# NEXTCLOUD-MARIADB
MYSQL_ROOT_PASSWORD=nextcloud
MYSQL_PASSWORD=nextcloud
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud

# NEXTCLOUD
MYSQL_HOST=nextcloud-db
REDIS_HOST=nextcloud-redis

# USING SENDGRID FOR SENDING EMAILS
MAIL_DOMAIN=blabla.org
MAIL_FROM_ADDRESS=nextcloud
SMTP_SECURE=ssl
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=465
SMTP_NAME=apikey
SMTP_PASSWORD=SG.asdasdasdasdasdasdsaasdasdsa
```

`nginx.conf`
```
I wont be pasting it here
in full text,
but it is included this github repo.
```

This is nginx web server configuration file, specifically setup
to support fastCGI PHP-FPM.

Taken from [this official nextcloud example
setup](https://github.com/nextcloud/docker/tree/master/.examples/docker-compose/insecure/mariadb-cron-redis/fpm/web)
and has one thing changed in it - the upstream hostname from `app` to `nextcloud-app`

```
upstream php-handler {
    server nextcloud-app:9000;
}
```

---

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

# Reverse proxy

[Nextcloud official documentation](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/reverse_proxy_configuration.html)
regarding reverse proxy.

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>
There are few extra directives here to fix some nextcloud warnings.

`Caddyfile`
```
nextcloud.{$MY_DOMAIN} {
    reverse_proxy nextcloud-web:80
    header Strict-Transport-Security max-age=31536000;
    redir /.well-known/carddav /remote.php/carddav 301
    redir /.well-known/caldav /remote.php/caldav 301
}
```

# First run

Nextcloud needs few minutes to start, then there is the initial configuration,
creating admin account and giving the database details as set in the `.env` file

![first-run-pic](https://i.imgur.com/EygHgKa.png)

The domain or IP you access nextcloud on this first run is added
to `trusted_domains` in `config.php`. 
Changing the domain later on will throw *"Access through untrusted domain"* error.</br>
Editing `nextcloud-data/config/config.php` and adding the new domain will fix it.

# Security & setup warnings

Nextcloud has a status check in *Settings > Administration > Overview*</br>
There are likely several warnings on a freshly spun containers.

##### The database is missing some indexes

`docker exec --user www-data --workdir /var/www/html nextcloud-app php occ db:add-missing-indices`

##### Some columns in the database are missing a conversion to big int

`docker exec --user www-data --workdir /var/www/html nextcloud-app php occ db:convert-filecache-bigint`

##### The "Strict-Transport-Security" HTTP header is not set to at least "15552000" seconds.

Helps to know what is [HSTS](https://www.youtube.com/watch?v=kYhMnw4aJTw).</br>
This warning is already fixed in the reverse proxy section in the caddy config,</br>
the line: `header Strict-Transport-Security max-age=31536000;`

##### Your web server is not properly set up to resolve "/.well-known/caldav" and Your web server is not properly set up to resolve "/.well-known/carddav".

This warning is already fixed in the reverse proxy section in the caddy config,</br>
The lines:</br>
`redir /.well-known/carddav /remote.php/carddav 301`</br>
`redir /.well-known/caldav /remote.php/caldav 301`

![status-pic](https://i.imgur.com/wjjd5CJ.png)


# Extra info

#### check if redis container works

At `https://<nexcloud url>/ocs/v2.php/apps/serverinfo/api/v1/info`</br>
ctrl+f for `redis`, should be in memcache.distributed and memcache.locking

You can also exec in to redis container:
- `docker exec -it nextcloud-redis /bin/sh`
- start monitoring: `redis-cli MONITOR`
- start browsing files on the nextcloud
- there should be activity in the monitoring

#### check if cron container works

- after letting Nextcloud run for a while
- in *settings > administration > basic settings*</br>
- background jobs should be set to Cron</br>
- the last job info should never be older than 10 minutes</br>

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

* down the nextcloud containers `docker-compose down`</br>
* delete the entire nextcloud directory</br>
* from the backup copy back the nextcloud directory</br>
* start the containers `docker-compose up -d`

# Backup of just user data

User data daily export using the
[official procedure.](https://docs.nextcloud.com/server/latest/admin_manual/maintenance/backup.html)</br>
For nextcloud it means entering the maintenance mode, doing a database dump
and backing up several directories containing data, configs, themes.</br>

For the script it just means database dump as borg backup and its deduplication
will deal with the directories, especially in the case of nextcloud where 
hundreds gigabytes can be stored.

#### Create a backup script

Placed inside `nextcloud` directory on the host.

`nextcloud-backup-script.sh`
```bash
#!/bin/bash

# MAINTENANCE MODE ON
docker container exec --user www-data --workdir /var/www/html nextcloud-app php occ maintenance:mode --on

# CREATE DATABASE DUMP, bash -c '...' IS USED OTHERWISE OUTPUT > WOULD TRY TO GO TO THE HOST
docker container exec nextcloud-db bash -c 'mysqldump --single-transaction -h nextcloud-db -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > /var/lib/mysql/BACKUP.nextcloud.database.sql'

# MAINTENANCE MODE OFF
docker container exec --user www-data --workdir /var/www/html nextcloud-app php occ maintenance:mode --off
```

The script must be **executable** - `chmod +x nextcloud-backup-script.sh`

Test run the script `sudo ./nextcloud-backup-script.sh`

The resulting database dump is in 
`nextcloud/nextcloud-data-db/BACKUP.nextcloud.database.sql`

#### Cronjob

Running on the host, so that the script will be periodically run.

* `su` - switch to root
* `crontab -e` - add new cron job</br>
* `0 23 * * * /home/bastard/docker/nextcloud/nextcloud-backup-script.sh`</br>
  runs it every day [at 23:00](https://crontab.guru/#0_23_*_*_*) 
* `crontab -l` - list cronjobs to check

# Restore the user data

Assuming clean start.

* start the containers: `docker-compose up -d`</br>
  let them run so they create the file structure
* down the containers: `docker-compose down`
* delete the directories `configs`, `data`, `themes` in the freshly created
  `nextcloud/nextcloud-data/`
* from the backup of /nextcloud/nextcloud-data/, copy the directories
  `configs`, `data`, `themes` in to the new `/nextcloud/nextcloud-data/`
* from the backup of /nextcloud/nextcloud-data-db/, copy the backup database
  named `BACKUP.nextcloud.database.sql` in to the new `/nextcloud/nextcloud-data-db/`
* start the containers: `docker-compose up -d`
* set the correct user ownership of the directories copied:</br>
  `docker exec --workdir /var/www/html nextcloud-app chown -R www-data:www-data config data themes`
* restore the database</br>
  `docker exec --workdir /var/lib/mysql nextcloud-db bash -c 'mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < BACKUP.nextcloud.database.sql'`
* turn off the maintenance mode:</br>
  `docker container exec --user www-data --workdir /var/www/html nextcloud-app php occ maintenance:mode --off`
* update the systems data-fingerprint:</br>
  `docker exec --user www-data --workdir /var/www/html nextcloud-app php occ maintenance:data-fingerprint`
* restart the containers: `docker-compose restart`
* log in
