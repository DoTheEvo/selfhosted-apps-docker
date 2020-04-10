# Nextcloud in docker

###### guide by example

![logo](https://i.imgur.com/6Wqs7J1.png)

### Purpose

File share & sync.

* [Official site](https://nextcloud.com/)
* [Github](https://github.com/nextcloud/server)
* [DockerHub](https://hub.docker.com/_/nextcloud/)

### Files and directory structure

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

### docker-compose

Official examples [here](https://github.com/nextcloud/docker/tree/master/.examples/docker-compose)

There are several options, default recomendation is apache.
Alternative is php-fpm as a stand alone container with either apache or ngnix.
Apache with php as a module is used in this setup.

Four containers are spin up
  - `nextcloud-db` - mariadb database where files and users meta data are stored
  - `nextcloud` - the nextcloud
  - `nextcloud-redis` - in memory data store for faster and responsive interface
  - `nextcloud-cron` - for being able to run maintnance cronjobs

Two persinstent storages
  - `nextcloud-data` bind mount - nextcloud app storage with web server and the works
  - `nextcloud-data-db` bind mount - database storage

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
        - NEXTCLOUD_TRUSTED_DOMAINS

    nextcloud-redis:
      image: redis:alpine
      container_name: nextcloud-redis
      hostname: nextcloud-redis
      restart: unless-stopped

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
  NEXTCLOUD_TRUSTED_DOMAINS=
  ```

### Reverse proxy

  Caddy v2 is used,
  details [here](https://github.com/DoTheEvo/Caddy-v2-examples)

  `Caddyfile`
  ```
  {
      # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
  }

  nextcloud.{$MY_DOMAIN} {
      reverse_proxy {
          to nextcloud:80
      }
  }
  ```
### First run

![first-run-pic](https://i.imgur.com/EygHgKa.png)


### Extra info

  - check if redis container works</br>
    exec in to redis container: `docker container exec -it nextcloud-redis /bin/sh`</br>
    start monitoring: `redis-cli MONITOR`</br>
    in browse start browsing files on the nextcloud,
    there should be lot of activity in the monitoring

  - check if cron container works</br>
    in *settings > administration > basic settings*</br>
    **Background jobs** should be set to **Cron** and the last job info
    should never be older than 10 minutes

    - in *settings > administration > overview*</br>
    nextcloud complains about missing indexes or big int

  - in *settings > administration > overview*</br>
    nextcloud complains about missing indexes or big int

    - docker exec -it nextcloud /bin/sh
    - chsh -s /bin/sh www-data
    - su www-data
    - cd /var/www/html
    - php occ db:add-missing-indices
    - php occ db:convert-filecache-bigint

  - in *settings > administration > overview*</br>
     not resolve "/.well-known/caldav" and "/.well-known/carddav"

     `docker container exec -it nextcloud /bin/sh`</br>
     `cd /etc/apache2/sites-enabled`</br>
     `echo >> 000-default.conf`</br>
     `echo Redirect 301 /.well-known/carddav /nextcloud/remote.php/dav >> 000-default.conf`</br>
     `echo Redirect 301 /.well-known/caldav /nextcloud/remote.php/dav >> 000-default.conf`

![interface-pic](https://i.imgur.com/cN1GUZw.png)

# #4 Update Nextcloud

  `docker-compose pull`
  `docker-compose up -d`
  `docker image prune`


# #5.Backup and restore

  likely there will be container running borg or borgmatic and cron
  
