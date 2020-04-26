# Watchtower in docker

###### guide by example

![logo](https://i.imgur.com/xXS2bzZ.png)

# Purpose

Automatic updates of containers.

* [Github](https://github.com/containrrr/watchtower)
* [DockerHub image used](https://hub.docker.com/r/containrrr/watchtower)

# Files and directory structure

```
/home
└── ~
    └── docker
        └── watchtower
            └── 🗋 docker-compose.yml
```

# docker-compose

[scheduled](https://pkg.go.dev/github.com/robfig/cron@v1.2.0?tab=doc#hdr-CRON_Expression_Format)
to run every saturday at midnight</br>
Heads up that it's not a typical cron format, seconds are the first digit.

`docker-compose.yml`
```yml
version: '3'
services:

  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower
    hostname: watchtower
    restart: unless-stopped
    env_file: .env
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

`.env`
```bash
# GENERAL
MY_DOMAIN=blabla.org
DEFAULT_NETWORK=caddy_net
TZ=Europe/Prague

# WATCHTOWER
WATCHTOWER_SCHEDULE=0 0 0 * * SAT
WATCHTOWER_CLEANUP=true
WATCHTOWER_TIMEOUT=30s
WATCHTOWER_DEBUG=false
WATCHTOWER_INCLUDE_STOPPED=false
```

# Update

  * [watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower) updates itself automaticly

  * manual image update</br>
    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`
