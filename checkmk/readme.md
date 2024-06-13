# checkmk

###### guide-by-example

![logo](https://i.imgur.com/yMDhlLJ.png)

# Purpose

Monitoring of machines, containers, services, logs, ...

* [Official site](https://checkmk.com/)
* [github](https://github.com/Checkmk/checkmk)

Monitoring in this case means gathering and showing information on how services
or machines or containers are running.
Can be cpu, io, ram, disk use, network throughput, latency,...
can be number of http requests, errors, results of backups...

# Overview

[Good youtube overview.](https://www.youtube.com/watch?v=7OnhuCsR7jg)

checkmk is a fork of nagios and is mostly written in python.<br>
Interesting fact is that there is no database where data are stored,
RRD files for metrics and plaintext logs for everything else.


![overview](https://i.imgur.com/HB0bLyU.png)

### Editions

[Docs](https://docs.checkmk.com/master/en/intro_setup.html#editions)

* **raw** - 100% open source, unlimited use, some features are missing
  or are harder to set up. For example no containers monitoring,
  no push mode from agents.
* **cloud** - full featured with better performing version of the monitoring micro core,
  but with 750 services limit

I am gonna go with cloud for now, as 750 sounds like enough for my use cases.

# Files and directory structure

```
/home/
 └── ~/
     └── docker/
         └── checkmk/
             ├── 🗁 checkmk_data/
             ├── 🗋 docker-compose.yml
             └── 🗋 .env
```

* `checkmk_data/` - a directory where checkmk_data stores its persistent data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

The two files must be provided.</br>
The directory is created by docker compose on the first run.

# docker-compose

A simple compose.<br>
Of note is use of ram as tmpfs mount into the container
and setting a 1024 limit for max open files by a single process.

*Note* - the port is only `expose`, since theres expectation of use
of a reverse proxy and accessing the services by hostname, not ip and port.

[Docs](https://docs.checkmk.com/latest/en/ports.html) on ports used in cmk.

`docker-compose.yml`
```yml
services:
  checkmk:
    image: checkmk/check-mk-raw
    container_name: checkmk
    hostname: checkmk
    restart: unless-stopped
    env_file: .env
    ulimits:
      nofile: 1024
    tmpfs:
      - /opt/omd/sites/cmk/tmp:uid=1000,gid=1000
    volumes:
      - ./checkmk_data:/omd/sites
      - /etc/localtime:/etc/localtime:ro
    expose:
      - "5000"      # webgui
    ports:
      - 8000:8000   # agents who push

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

# CMK

CMK_SITE_ID=dom
CMK_PASSWORD=WUx666yd0qCWh
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

## Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```php
cmk.{$MY_DOMAIN} {
  reverse_proxy checkmk:5000
}
```



---
---



# Push


# Alerts


# Logs

# Update

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

# Backup and restore

#### Backup

Using [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the entire directory.

#### Restore

* down the containers `docker-compose down`</br>
* delete the entire monitoring directory</br>
* from the backup copy back the monitoring directory</br>
* start the containers `docker-compose up -d`
