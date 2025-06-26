# Immich in docker

###### guide-by-example

![logo](https://i.imgur.com/RpFC0Rg.png)

# Purpose & Overview

 Selfhosted google photos alternative.

* [Official site](https://immich.app/)
* [Github](https://github.com/immich-app/immich)

Immich is a selfhosted photo and video management solution,
written mostly in javascript with Dart for android/ios apps
and postgress for the database. There is some python for machine learning.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── immich/
            ├── 🗁 library/
            ├── 🗁 postgress/
            ├── 🗋 .env
            └── 🗋 compose.yml
```

* `library` - all the photos and videos uploaded
* `postgress` - the database data, metadata
* `.env` - a file containing environment variables for docker compose
* `compose.yml` - a docker compose file, telling docker how to run the containers

Only the two files are required. The directories are created on the first run.

# compose

[compose](https://github.com/immich-app/immich/tree/main/docker) on github.

Immich has prepared compose file for the deployment.<br>
I usually edit them to fit the way I do things,
but here I made only two changes - added network stuff and made database container
pull env values from the .env file.

`docker-compose.yml`
```yml
#
# WARNING: To install Immich, follow our guide: https://immich.app/docs/install/docker-compose
#
# Make sure to use the docker-compose.yml of the current release:
#
# https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
#
# The compose file on main may not be compatible with the latest release.

name: immich

services:
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION:-release}
    # extends:
    #   file: hwaccel.transcoding.yml
    #   service: cpu # set to one of [nvenc, quicksync, rkmpp, vaapi, vaapi-wsl] for accelerated transcoding
    volumes:
      # Do not edit the next line. If you want to change the media storage location on your system, edit the value of UPLOAD_LOCATION in the .env file
      - ${UPLOAD_LOCATION}:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    env_file:
      - .env
    ports:
      - '2283:2283'
    depends_on:
      - redis
      - database
    restart: always
    healthcheck:
      disable: false

  immich-machine-learning:
    container_name: immich_machine_learning
    # For hardware acceleration, add one of -[armnn, cuda, rocm, openvino, rknn] to the image tag.
    # Example tag: ${IMMICH_VERSION:-release}-cuda
    image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}
    # extends: # uncomment this section for hardware acceleration - see https://immich.app/docs/features/ml-hardware-acceleration
    #   file: hwaccel.ml.yml
    #   service: cpu # set to one of [armnn, cuda, rocm, openvino, openvino-wsl, rknn] for accelerated inference - use the `-wsl` version for WSL2 where applicable
    volumes:
      - model-cache:/cache
    env_file:
      - .env
    restart: always
    healthcheck:
      disable: false

  redis:
    container_name: immich_redis
    image: docker.io/valkey/valkey:8-bookworm@sha256:fec42f399876eb6faf9e008570597741c87ff7662a54185593e74b09ce83d177
    healthcheck:
      test: redis-cli ping || exit 1
    restart: always

  database:
    container_name: immich_postgres
    image: ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:5f6a838e4e44c8e0e019d0ebfe3ee8952b69afc2809b2c25f7b0119641978e91
    env_file:
      - .env
    volumes:
      # Do not edit the next line. If you want to change the database storage location on your system, edit the value of DB_DATA_LOCATION in the .env file
      - ${DB_DATA_LOCATION}:/var/lib/postgresql/data
    restart: always

volumes:
  model-cache:

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

# all the variables at https://immich.app/docs/install/environment-variables

# The location where your uploaded files are stored
UPLOAD_LOCATION=./library

# The location where your database files are stored. Network shares are not supported for the database
DB_DATA_LOCATION=./postgres

# The Immich version to use. You can pin this to a specific version like "v1.71.0"
IMMICH_VERSION=release

# Connection secret for postgres. You should change it to a random password
# Please use only the characters `A-Za-z0-9`, without special characters or spaces
DB_PASSWORD=rockydust

# POSTGRES VARIABLES ORIGINALLY IN THE COMPOSE FILE
POSTGRES_PASSWORD=rockydust
POSTGRES_USER=postgres
POSTGRES_DB=immich
POSTGRES_INITDB_ARGS='--data-checksums'
# Uncomment the DB_STORAGE_TYPE: 'HDD' var if your database isn't stored on SSDs
# DB_STORAGE_TYPE: 'HDD'

# The values below this line do not need to be changed
###################################################################################
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```php
photos.{$MY_DOMAIN} {
  reverse_proxy immich_server:2283
}
```

# First run

![first_run](https://i.imgur.com/SvnDhul.png)

Click through the initial setup.
Use a real email as it will be used for notifications and stuff.


---

# Email notifications setup

* Admin account > right top corner - Administration > Settings > Notifications
* Email
  * Host: smtp-relay.brevo.com
  * Port: 587
  * Username: \<email used for brevo registration\>
  * Password: \<generated smtp long key\>
  * From address: if on brevo you verified domain than whatevers there
  * Test - an email will be send to current account email address

# Trouble shooting


# Update

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

It is **strongly recommended** to now add current **tags** to the images in the compose.<br>
Tags will allow you to easily return to a working state if an update goes wrong.


# Backup and restore

#### Backup

  
#### Restore


# Backup of just user data


#### Backup script


#### Cronjob - scheduled backup

# Restore the user data

