# Nextcloud in docker

###### guide by example

![logo](https://i.imgur.com/6Wqs7J1.png)

## Purpose

File share & sync.

* [Official site](https://nextcloud.com/)
* [Github](https://github.com/nextcloud/server)
* [DockerHub](https://hub.docker.com/_/nextcloud/)

## Files and directory structure

  ```
  /home
  └── ~
      └── docker
          └── nextcloud
              ├── 🗁 nextcloud-data
              ├── 🗁 nextcloud-data-db
              ├── 🗋 .env
              ├── 🗋 docker-compose.yml
              └── 🗋 nextcloud-backup-script.sh
  ```

## docker-compose

Official examples [here](https://github.com/nextcloud/docker/tree/master/.examples/docker-compose)

Four containers are spin up
  - `nextcloud` - nextcloud app with apache web server with php as a module 
  - `nextcloud-db` - mariadb database where files and users meta data are stored
  - `nextcloud-redis` - in memory file cashing and more reliable tranactional file locking
  - `nextcloud-cron` - for being able to run maintnance cronjobs

  `docker-compose.yml`

  ```
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

    nextcloud:
      image: nextcloud:apache
      container_name: nextcloud
      hostname: nextcloud
      restart: unless-stopped
      depends_on:
        - nextcloud-db
        - nextcloud-redis
      links:
        - nextcloud-db
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

    nextcloud-cron:
      image: nextcloud:apache
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
  ```
  # GENERAL
  MY_DOMAIN=blabla.org
  DEFAULT_NETWORK=caddy_net
  TZ=Europe/Prague

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

## Reverse proxy

  Caddy v2 is used,
  details [here](https://github.com/DoTheEvo/Caddy-v2-examples)
  
  There are few extra directives here to fix some nextcloud warnings

  `Caddyfile`
  ```
  {
      # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
  }

  nextcloud.{$MY_DOMAIN} {
      reverse_proxy nextcloud:80
      header Strict-Transport-Security max-age=31536000;
      redir /.well-known/carddav /remote.php/carddav 301
      redir /.well-known/caldav /remote.php/caldav 301
  }
  ```

## First run

Nextcloud needs few minutes to start, then there is the initial configuration.
Creating adming account and giving the database details as set in the `.env` file

![first-run-pic](https://i.imgur.com/EygHgKa.png)


## Security & setup warnings

Nextcloud has status check in *Settings > Administration > Overview*</br>
There are likely several warnings on a freshly spun container.

  - **The database is missing some indexes**
    - `docker exec --user www-data --workdir /var/www/html nextcloud php occ db:add-missing-indices`

  - **Some columns in the database are missing a conversion to big int**
    - `docker exec --user www-data --workdir /var/www/html nextcloud php occ db:convert-filecache-bigint`

  - **The "Strict-Transport-Security" HTTP header is not set to at least "15552000" seconds.**
    - helps to know what [HSTS means](https://www.youtube.com/watch?v=kYhMnw4aJTw)
    - fixed in the reverse proxy section above in caddy config
    - the line `header Strict-Transport-Security max-age=31536000;`

  - **Your web server is not properly set up to resolve "/.well-known/caldav"** and **Your web server is not properly set up to resolve "/.well-known/carddav".**
    - fixed in the reverse proxy section above in caddy config
    - `redir /.well-known/carddav /remote.php/carddav 301`
    - `redir /.well-known/caldav /remote.php/caldav 301`

![status-pic](https://i.imgur.com/wjjd5CJ.png)


## Extra info

  - **check if redis container works**</br>
    at `https://<nexcloud url>/ocs/v2.php/apps/serverinfo/api/v1/info`</br>
    ctrl+f for `redis`, should be in memcache.distributed and memcache.locking

    you can also exec in to redis container: `docker exec -it nextcloud-redis /bin/bash`</br>
    start monitoring: `redis-cli MONITOR`</br>
    start browsing files on the nextcloud,
    there should be activity in the monitoring

  - **check if cron container works**</br>
    in *settings > administration > basic settings*</br>
    Background jobs should be set to Cron</br>
    the last job info should never be older than 10 minutes</br>

## Update

  * [watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower) updates the image automaticly

  * manual image update</br>
    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`

## Backup and restore

  * **backup** using [borgbackup setup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
  that makes daily snapshot of the entire directory
    
  * **restore**</br>
    down the nextcloud containers `docker-compose down`</br>
    delete the entire nextcloud directory</br>
    from the backup copy back the nextcloud directortory</br>
    start the container `docker-compose up -d`

### Backup of just user data

user-data daily export using the [official procedure.](https://docs.nextcloud.com/server/latest/admin_manual/maintenance/backup.html)</br>
For nextcloud it means entering maintenance mode,
database dump and backing up several directories containing data, configs, themes.</br>
The created backup files are overwriten on every run of the script,
but borg backup is daily making snapshot of the entire directory.

* **create a backup script**</br>
    placed inside `nextcloud` directory on the host

    `nextcloud-backup-script.sh`
    ```
    #!/bin/bash

    # MAINTENANCE MODE ON
    docker container exec --user www-data --workdir /var/www/html nextcloud php occ maintenance:mode --on

    # CREATE DATABASE DUMP, bash -c '...' IS USED OTHERWISE OUTPUT > WOULD TRY TO GO TO THE HOST
    docker container exec nextcloud-db bash -c 'mysqldump --single-transaction -h nextcloud-db -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > /var/lib/mysql/BACKUP.nextcloud.database.sql'

    # ARCHIVE DIRECTORIES
    docker container exec --workdir /var/www/html nextcloud tar -czPf BACKUP.nextcloud.data.tar config data themes

    # MAINTENANCE MODE OFF
    docker container exec --user www-data --workdir /var/www/html nextcloud php occ maintenance:mode --off
    ```

    the script must be **executabe** - `chmod +x bookstack-backup-script.sh`

* **cronjob** on the host</br>
  `crontab -e` - add new cron job</br>
  `0 2 * * * /home/bastard/docker/bookstack/bookstack-backup-script.sh` - run it [at 02:00](https://crontab.guru/#0_2_*_*_*)</br>
  `crontab -l` - list cronjobs

### Restore the user data

  Assuming clean start, first restore the database before running the app container.

  * start the containers: `docker-compose up -d`</br>
    let it run so it creates its file structure
  * down the containers: `docker-compose up -d`
  * from backup copy the direcotries `data`, `configs`, `themes` in to `nextcloud-data` replacing the ones in place
  * from backup copy the backup database in to `nextcloud-data-db`
  * start the containers: `docker-compose up -d`
  * set the correct user ownership of the direcotries copied:</br>
    `docker exec --workdir /var/www/html nextcloud chown -R www-data:www-data config data themes`
  * restore the database</br>
    `docker exec --workdir /var/lib/mysql nextcloud-db bash -c 'mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < BACKUP.nextcloud.database.sql'`
  * turn off the maintenance mode:</br>
    `docker container exec --user www-data --workdir /var/www/html nextcloud php occ maintenance:mode --off`
  * update the systems data-fingerprint:</br>
    `docker exec --user www-data --workdir /var/www/html nextcloud php occ maintenance:data-fingerprint`
  * restart the containers: `docker-compose restart`
  * log in
