# Gatus in docker

###### guide-by-example

![logo](https://i.imgur.com/ETVqtWL.png)

# Purpose & Overview

Uptime monitoring and notifications.

* [The Official Site](https://gatus.io/)
* [Github](https://github.com/TwiN/gatus)
* [DockerHub](https://hub.docker.com/r/twinproduction/gatus)

Simple, light, modern uptime monitoring of sites, hosts, ports, DNS records,...
with rich notification system.<br>
What makes Gatus different, from the popular Uptime Kuma, is the way one
declares what to monitor. Instead of clicking through a web site,
filling text inputs, checking checkboxes, marking radio buttons,...  
**gatus uses a single config file** which makes it easy to backup,
or fast deploy somewhere, or even automate.

Written in golang, this deployment uses sqlite for database,
but can work with postgress or just live in memory.
 
---

![interface-pic](https://i.imgur.com/RXfLUq5.jpeg)

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── gatus/
            ├── 🗁 gatus_config/
            ├── 🗁 gatus_data/
            └── 🗋 compose.yml
```

* `gatus_config` - where to place the config files
* `gatus_data` - persistent data, contains sqlite database
* `.env` - a file containing environment variables for the compose
* `compose.yml` - a docker compose file, telling docker how to run the container

You need to create `gatus_config` directory with the config.yml
and provide the two files - compose and .env

# docker compose

Based on [the sqlite example.](https://github.com/TwiN/gatus?tab=readme-ov-file#storage)<br>
It's a simple, single container setup.<br>
If using reverse proxy `ports:` can be changed to `expose:`,
if they are on the same network.

`compose.yml`
```yml
services:
  gatus:
    image: twinproduction/gatus
    container_name: gatus
    hostname: gatus
    restart: unless-stopped
    env_file: .env
    ports:
      - "8080"
    volumes:
      - ./gatus_config:/config
      - ./gatus_data:/data/

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
gatus.{$MY_DOMAIN} {
  reverse_proxy gatus:8080
}
```

# Configuration

More complex setups can use several config files,
here is just an exaple how to monitor few web servers and use 
[ntfy](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal)
for alerts.<br>
Theres an extenstive [documentation](https://gatus.io/docs)
and [github readmes](https://github.com/TwiN/gatus) for more detailed info,
plus gatus got pretty popular so there are
[youtube videos.](https://www.youtube.com/results?search_query=gatus+monitoring)

* *extra info:*<br>
  Changes to the config are applied on save, no container up/down is required.

```yml
ui:
  ui.dark-mode: "true"

storage:
  type: sqlite
  path: /data/data.db

alerting:
  ntfy:
    topic: "gatus"
    url: "https://ntfy.example.com"
    click: "https://gatus.example.com"
    default-alert:
      send-on-resolved: true
      failure-threshold: 2
      success-threshold: 1

endpoints:
  - name: test1
    url: "https://test1.lalala/"
    interval: 5m
    conditions:
      - "[STATUS] == 200"
      - "[RESPONSE_TIME] < 2000"
    alerts:
       - type: ntfy

  - name: test2
    group: blabla
    url: "https://test2.lalala/"
    interval: 5m
    conditions:
      - "[STATUS] == 200"
      - "[RESPONSE_TIME] < 2000"
    alerts:
       - type: ntfy
```

### Certificate check

You should have automatic cert renewal, I love caddy for that,
but sometimes for geoblocking and dns reasons, you gotta do it manually.<br>
Gatus checks cert automatically without you defining anything,
but only once the certificate expire it would send an alert.

To define it few days in advance...

```
- name: test1
  url: "https://test1.lalala/"
  interval: 5m
  conditions:
    - "[STATUS] == 200"
    - "[RESPONSE_TIME] < 2000"
    - "[CERTIFICATE_EXPIRATION] > 5d"
  alerts:
     - type: ntfy
```

# Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

# Backup and restore

#### Backup
  
#### Restore
