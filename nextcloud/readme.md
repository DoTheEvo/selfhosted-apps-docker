# Nextcloud in docker

###### guide by example

chapters

1. [Docker compose](#1-docker-compose)
2. [Reverse proxy using caddy v2](#2-Reverse-proxy-using-caddy-v2)
3. [Some stuff afterwards](#3-Some-stuff-afterwards)
4. [Update Nextcloud](#4-Update-Nextcloud)
5. [Backup and restore](#5-Backup-and-restore)

# #1 Docker compose

Official examples [here](https://github.com/nextcloud/docker/tree/master/.examples/docker-compose)

There are several options, default recomendation is apache.
Alternative is fpm php as stand alone container with either apache or ngnix.</br>
The default apache with php as a module is used in this setup

- **Create a new docker network**</br> `docker network create caddy_net`</br>
All nextcloud containers must be on the same network.

- **Create a directory structure**
Where nextcloud docker stuff will be organized.</br>
Here will be `~/docker/nextcloud`.</br>

  ```
  /home
  └── ~
      └── docker
          └── nextcloud
              ├── nextcloud-data
              ├── .env
              └── docker-compose.yml
  ```
  
  - `nextcloud-data` the directory where '/var/www/html' will be bind-mounted
  - `.env` the env file with the variables
  - `docker-compose.yml` the compose file


- **Create `.env` file**</br>

  `.env`
  ```
  # GENERAL
  MY_DOMAIN=blabla.org
  DEFAULT_NETWORK=caddy_net

  # NEXTCLOUD-MARIADB
  MYSQL_ROOT_PASSWORD=nextcloud
  MYSQL_PASSWORD=nextcloud
  MYSQL_DATABASE=nextcloud
  MYSQL_USER=nextcloud
  ```

- **Create `docker-compose.yml` file**</br>
  Four containers are spin up
  - nextcloud-db - mariadb database where files and users meta data are stored
  - nextcloud-redis - in memory data store for more responsive interface
  - nextcloud-app - the nextcloud
  - nextcloud-cron - for being able to run maintnance cronjobs

  Two persinstent storages
    - nextcloud-db named volume - nextcloud-db:/var/lib/mysql
    - nextcloud-app bind mount - ./nextcloud-data/:/var/www/html

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
          - nextcloud-db:/var/lib/mysql
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
        image: nextcloud:apache
        container_name: nextcloud
        hostname: nextcloud
        restart: unless-stopped
        depends_on:
          - nextcloud-db
          - nextcloud-redis
        links:
          - nextcloud-db
        ports:
          - 8080:80
        volumes:
          - ./nextcloud-data/:/var/www/html
        environment:
          - MYSQL_HOST=nextcloud-db
          - REDIS_HOST=nextcloud-redis
          - NEXTCLOUD_TRUSTED_DOMAINS

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

    volumes:
      nextcloud-db:

    networks:
      default:
        external:
          name: $DEFAULT_NETWORK

    ```

- **Run docker compose**

  `docker-compose -f docker-compose.yml up -d`

# #2 Reverse proxy using caddy v2

  Provides reverse proxy so that more services can run on this docker host,</br>
  and also provides https.</br>
  This is a basic setup, for more details here is
  [Caddy v2 tutorial + examples](https://github.com/DoTheEvo/Caddy-v2-examples)

- **Have nextcloud to Caddyfile**</br>

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

- **Create docker-compose.yml**</br>

  `docker-compose.yml`
  ```
  version: "3.7"

  services:
    caddy:
      image: "caddy/caddy:alpine"
      container_name: "caddy"
      hostname: "caddy"
      ports:
        - "80:80"
        - "443:443"
      volumes:
        - "./Caddyfile:/etc/caddy/Caddyfile:ro"
        - caddy_lets_encrypt_storage:/data
        - caddy_config_storage:/config
      environment:
        - MY_DOMAIN

  networks:
    default:
      external:
        name: $DEFAULT_NETWORK

  volumes:
    caddy_lets_encrypt_storage:
    caddy_config_storage:
  ```
  Make sure docker-compose.yml has the .env file with the same variables for 
  $DEFAULT_NETWORK and $MY_DOMAIN

- **Run it**

  `docker-compose -f docker-compose.yml up -d`

  If something is fucky use `docker logs caddy` to see what is happening.
  Restarting the container can help getting the certificates, if its stuck there.
  Or investigate inside `docker container exec -it caddy /bin/sh`,
  trying to ping hosts that are suppose to be reachable for example.

# #3. Some stuff afterwards

  - in settings > overview, nextcloud complains about missing indexes or big int
    - docker exec -it nextcloud /bin/sh
    - chsh -s /bin/sh www-data
    - su www-data
    - cd /var/www/html
    - php occ db:add-missing-indices
    - php occ db:convert-filecache-bigint

# #4 Update Nextcloud

  `docker-compose pull`
  `docker-compose up -d`
  `docker image prune`


# #5.Backup and restore

  likely there will be container running borg or borgmatic and cron
  
