# Uptime Kuma in docker

###### guide-by-example

![logo](https://i.imgur.com/Q51w85x.png)

# Purpose & Overview

Uptime monitoring and notifications. 

* [Github](https://github.com/louislam/uptime-kuma)

Simple, modern, uptime monitoring of sites, hosts, ports, containers,
with rich notification system.

Written in javascript.
 
---

![interface-pic](https://i.imgur.com/a99GvY2.jpg)

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── uptimekuma/
            ├── 🗁 uptimekuma_data/
            └── 🗋 docker-compose.yml
```

* `uptimekuma_data` - persistent data, contains sqlite database
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the two files.</br>
The directory is created by docker compose on the first run.

# docker-compose

It's a simpler, single container approach. 

`docker-compose.yml`
```yml
services:
  uptimekuma:
    image: louislam/uptime-kuma:1
    container_name: uptimekuma
    hostname: uptimekuma
    restart: unless-stopped
    ports:
      - "3001:3001"
    volumes:
      - ./uptimekuma_data:/app/data

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true      
```

`.env`
```bash
# GENERAL
TZ=Europe/Bratislava
DOCKER_MY_NETWORK=caddy_net
```
# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).

`Caddyfile`
```php
uptime.{$MY_DOMAIN} {
  reverse_proxy uptimekuma:3001
}
```

# Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

# Backup and restore

#### Backup

should be just backup of `uptimekuma_data` directory

not tested yet
  
#### Restore
