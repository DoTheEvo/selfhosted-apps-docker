# Nextcloud in docker

###### guide-by-example

![logo](https://i.imgur.com/VXSovC9.png)

# Purpose & Overview

File share & sync.

* [Official site](https://nextcloud.com/)
* [Github](https://github.com/nextcloud/server)
* [DockerHub](https://hub.docker.com/_/nextcloud/)

Nextcloud is an open source software for sharing files, calendar, general office
collaboration stuff. Most people know it and use it as an alternative
to onedrive/google drive.

The Nextcloud server is written in PHP and JavaScript.
For remote access it employs sabre/dav, an open-source WebDAV server.
It is designed to work with most of the databases.

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
            ├── 🗁 nextcloud_data/
            ├── 🗁 nextcloud_db_data/
            ├── 🗋 .env
            ├── 🗋 docker-compose.yml
            ├── 🗋 nginx.conf
            └── 🗋 nextcloud-backup-script.sh
```

* `nextcloud_data/` - users actual data and web app data
* `nextcloud_db_data/` - database data - users and files metadata, configuration
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers
* `nginx.conf` - nginx web server configuration file
* `nextcloud-backup-script.sh` - a backup script, to be run daily

You only need to provide the files.</br>
The directories are created by docker compose on the first run.

# docker-compose

Official examples [here](https://github.com/nextcloud/docker/tree/master/.examples/docker-compose)

Five containers to spin up

* **nextcloud-app** - nextcloud backend app that stores the files and facilitate 
  the sync and runs the apps(calendar, notes, phonetrack,...)
* **nextcloud-db** - mariadb database storing files-metadata and users-metadata
* **nextcloud-web** - nginx web server with fastCGI PHP-FPM support
* **nextcloud-redis** - in memory file caching and more reliable transactional
  file locking
* **nextcloud-cron** - for periodic maintenance in the background

Note that `nextcloud_data` is mounted in 3 containers.

`docker-compose.yml`
```yml
version: '3'
services:

  nextcloud-db:
    image: mariadb
    container_name: nextcloud-db
    hostname: nextcloud-db
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW --innodb_read_only_compressed=OFF
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./nextcloud_data_db:/var/lib/mysql

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
    env_file: .env
    depends_on:
      - nextcloud-db
      - nextcloud-redis
    volumes:
      - ./nextcloud_data/:/var/www/html

  nextcloud-web:
    image: nginx:alpine
    container_name: nextcloud-web
    hostname: nextcloud-web
    restart: unless-stopped
    volumes:
      - ./nextcloud_data/:/var/www/html:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    expose:
      - 80:80

  nextcloud-cron:
    image: nextcloud:fpm-alpine
    container_name: nextcloud-cron
    hostname: nextcloud-cron
    restart: unless-stopped
    volumes:
      - ./nextcloud_data/:/var/www/html
    entrypoint: /cron.sh
    depends_on:
      - nextcloud-db
      - nextcloud-redis

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

# NEXTCLOUD-MARIADB
MYSQL_ROOT_PASSWORD=nextcloud
MARIADB_AUTO_UPGRADE=1
MARIADB_DISABLE_UPGRADE_BACKUP=1
MYSQL_PASSWORD=nextcloud
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud

# NEXTCLOUD-APP
MYSQL_HOST=nextcloud-db
REDIS_HOST=nextcloud-redis
OVERWRITEPROTOCOL=https
TRUSTED_PROXIES=caddy
NC_default_phone_region=SK   # CHANGE TO YOUR COUNTRY CODE

# USING SENDINBLUE FOR SENDING EMAILS
MAIL_DOMAIN=nextcloud
MAIL_FROM_ADDRESS=nextcloud
SMTP_SECURE=tls
SMTP_HOST=smtp-relay.sendinblue.com
SMTP_PORT=587
SMTP_NAME=<registration-email@gmail.com>
SMTP_PASSWORD=<smtp-key-goes-here>
```

`nginx.conf`
```
Not be pasted here, too long.
It is included in this github repo.
```

[nginx.conf](https://raw.githubusercontent.com/DoTheEvo/selfhosted-apps-docker/master/nextcloud/nginx.conf)<br>
This is nginx web server configuration file, specifically setup
to support fastCGI PHP-FPM.<br>
From [this official nextcloud example
setup](https://github.com/nextcloud/docker/tree/master/.examples/docker-compose/insecure/mariadb/fpm/web)
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
```php
nextcloud.{$MY_DOMAIN} {
    header Strict-Transport-Security max-age=31536000;
    redir /.well-known/carddav /remote.php/carddav 301
    redir /.well-known/caldav /remote.php/caldav 301
    redir /.well-known/webfinger /index.php/.well-known/webfinger 301
    redir /.well-known/nodeinfo /index.php/.well-known/nodeinfo 301
    reverse_proxy nextcloud-web:80
}
```

# First run

Nextcloud needs few moments to start, then there is the initial configuration,
creating admin account.</br>
If database env variables were not used then also the database info
would be required here.

![first-run-pic](https://i.imgur.com/lv1x9GF.png)

The domain or IP you access nextcloud on this first run is added
to `trusted_domains` in `config.php`. 
Changing the domain later on will throw *"Access through untrusted domain"* error.</br>
Editing `nextcloud_data/config/config.php` and adding the new domain will fix it.

# Security & setup warnings

Nextcloud has a status check in *Settings > Administration > Overview*</br>
There could be some warnings there, but if following this guide, it should be 
all good. As `Caddyfile` and `.env` file should take care of it.

[Here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/a86c8498dc8ebc59546660701a54b839bf417516/nextcloud#security--setup-warnings)
is a link to an older commit that talks in more detail on possible stuff here.<br>
But fuck writing on that noise when nextcloud is now doing phone number area
code notification there.

![status-pic](https://i.imgur.com/0nltwrn.png)

# Troubleshooting

* moving between docker hosts, might need to take ownership of directories<br>
  exec in to `nextcloud-app`; `/var/www/html`; `chown www-data:www-data *`

# Extra info

#### check if redis container works

At `https://<nexcloud url>/ocs/v2.php/apps/serverinfo/api/v1/info`</br>
ctrl+f for `redis`, if it's present it means nexcloud is set to use it.

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

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

Updates tend to be problematic with Nexcloud. Inestigating what went wrong 
in between major version updates...  have backups before doing update.
And have the god damn tags on docker images.

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

User's data daily export going by the
[official procedure.](https://docs.nextcloud.com/server/latest/admin_manual/maintenance/backup.html)</br>
For nextcloud it means entering the maintenance mode, doing a database dump
and backing up several directories containing data, configs, themes.</br>

Daily kopia/borg backup run takes care of backing up the directories.
So only database dump is needed and done with the script.</br>

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

Test run the script `sudo ./nextcloud-backup-script.sh`</br>
The resulting database dump is in 
`nextcloud/nextcloud_data_db/BACKUP.nextcloud.database.sql`

#### Cronjob

Running on the host, so that the script will be periodically run.

* `su` - switch to root
* `crontab -e` - add new cron job</br>
* `0 23 * * * /home/bastard/docker/nextcloud/nextcloud-backup-script.sh`</br>
  runs it every day [at 23:00](https://crontab.guru/#0_23_*_*_*) 
* `crontab -l` - list cronjobs to check

# Restore the user data

[The official docs.](https://docs.nextcloud.com/server/latest/admin_manual/maintenance/restore.html)

Assuming clean start.

* start the containers: `docker-compose up -d`</br>
  let them run so they create the file structure
* down the containers: `docker-compose down`
* delete the directories `config`, `data`, `themes` in the freshly created
  `nextcloud/nextcloud_data/`
* from the backup of `/nextcloud/nextcloud_data/`, copy the directories
  `configs`, `data`, `themes` in to the new `/nextcloud/nextcloud_data/`
* from the backup of `/nextcloud/nextcloud_data_db/`, copy the backup database
  named `BACKUP.nextcloud.database.sql` in to the new `/nextcloud/nextcloud_data_db/`
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
