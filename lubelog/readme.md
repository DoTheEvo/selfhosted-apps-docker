# LubeLog in docker

###### guide-by-example

![logo](https://i.imgur.com/7zjQQzy.png)

# Purpose & Overview

 Vehicle service records and maintainence tracker.

* [Official site](https://lubelogger.com/)
* [Github](https://github.com/hargata/lubelog)

LubeLogger is a new open source vehicle info dump place.

Written in javascript with LiteDB file based database.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── LubeLog/
            ├── 🗁 lubelog_config/
            ├── 🗁 lubelog_data/
            ├── 🗁 lubelog_documents/
            ├── 🗁 lubelog_images/
            ├── 🗁 lubelog_keys/
            ├── 🗁 lubelog_log/
            ├── 🗁 lubelog_temp/
            ├── 🗁 lubelog_translations/
            ├── 🗋 .env
            └── 🗋 docker-compose.yml
```

* `lubelog directories` - with data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

Only the two files are required. The directories are created on the first run.

# docker-compose

[Dockercompose](https://github.com/hargata/lubelog/blob/main/docker-compose.yml)
from the github page used as a template.

`docker-compose.yml`
```yml
services:
  lubelog:
    image: ghcr.io/hargata/lubelogger:latest
    container_name: lubelog
    hostname: lubelog
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./lubelog_config:/App/config
      - ./lubelog_data:/App/data
      - ./lubelog_translations:/App/wwwroot/translations
      - ./lubelog_documents:/App/wwwroot/documents
      - ./lubelog_images:/App/wwwroot/images
      - ./lubelog_temp:/App/wwwroot/temp
      - ./lubelog_log:/App/log
      - ./lubelog_keys:/root/.aspnet/DataProtection-Keys
    ports:
      - 8080:8080

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

#LUBELOG
LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8
MailConfig__EmailServer=smtp-relay.brevo.com
MailConfig__EmailFrom=lubelog@example.com
MailConfig__UseSSL=True
MailConfig__Port=587
MailConfig__Username=<registration-email@gmail.com>
MailConfig__Password=<brevo-smtp-key-goes-here>
LOGGING__LOGLEVEL__DEFAULT=Error
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```php
auto.{$MY_DOMAIN} {
    reverse_proxy lubelog:80
}
```

# First run

---


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

