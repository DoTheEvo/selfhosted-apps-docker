# Watchtower in docker

###### guide by example

![logo](https://i.imgur.com/xXS2bzZ.png)

# Purpose

Automatic updates of docker containers.

* [Github](https://github.com/containrrr/watchtower)
* [DockerHub image used](https://hub.docker.com/r/containrrr/watchtower)

Watchtower is an application that will monitor the running Docker containers
and watch for changes to the images that those containers
were originally started from. If watchtower detects that an image has changed,
it will automatically restart the container using the new image.

As of now, Watchtower needs to always pull images to know if they changed.
This can be bandwidth intensive, so its scheduled checks should account for this.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── watchtower/
            ├── .env
            └── docker-compose.yml
```

* `.env` - a file containing environmental variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to build the container

Only these two files must be provided.

# docker-compose

Scheduled to run every saturday at midnight using environmental variable.</br>
Heads up that not a typical cron format is used,
[seconds are the first digit](https://pkg.go.dev/github.com/robfig/cron@v1.2.0?tab=doc#hdr-CRON_Expression_Format).

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
TZ=Europe/Bratislava

# WATCHTOWER
WATCHTOWER_SCHEDULE=0 0 0 * * SAT
WATCHTOWER_CLEANUP=true
WATCHTOWER_TIMEOUT=30s
WATCHTOWER_DEBUG=false
WATCHTOWER_INCLUDE_STOPPED=false
```

# Update

* [watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower)
updates itself automatically

* manual image update</br>
  `docker-compose pull`</br>
  `docker-compose up -d`</br>
  `docker image prune`
