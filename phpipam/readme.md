# phpIPAM in docker

###### guide-by-example

![logo](https://i.imgur.com/GrWPooR.png)

# WORK IN PROGRESS
# WORK IN PROGRESS
# WORK IN PROGRESS

# Purpose

IP address managment, LAN information and documentation tool.


* [Official site](https://phpipam.net/)
* [Github](https://github.com/phpipam/phpipam)
* [DockerHub image used](https://hub.docker.com/r/phpipam/phpipam-www)

IPAM is a universal term that stands for
[IP Address Management](https://en.wikipedia.org/wiki/IP_address_management).<br>

phpIPAM is open source tool fullfilling this purpose.
Coded in php and using mariadb for database.

My exposure to it is limited and at this moment 
So far use is just tracking of used IP.

Can be used to keep inventory of IT hardware, or organization of server racks.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── phpipam/
            ├── phpipam-mariadb-data/
            ├── .env
            └── docker-compose.yml
```

* `phpipam-mariadb-data/` - a directory where phpipam will store its database data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the files.<br>
The directory is created by docker compose on the first run.

# docker-compose

`docker-compose.yml`
```yml
version: '3'
services:

  phpipam-web:
    image: phpipam/phpipam-www:latest
    container_name: phpipam-web
    hostname: phpipam-web
    # ports:
    #   - "80:80"
    restart: unless-stopped
    env_file: .env
    depends_on:
      - phpipam-mariadb

  phpipam-mariadb:
    image: mariadb:latest
    container_name: phpipam-mariadb
    hostname: phpipam-mariadb
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./phpipam-mariadb-data:/var/lib/mysql

  networks:
  default:
    external:
      name: $DOCKER_MY_NETWORK
```

`.env`
```bash
# GENERAL
DOCKER_MY_NETWORK=caddy_net
TZ=EuropeBratislava

IPAM_DATABASE_HOST=phpipam-mariadb
IPAM_DATABASE_PASS=my_secret_phpipam_pass
IPAM_DATABASE_WEBHOST=%
MYSQL_ROOT_PASSWORD=my_secret_mysql_root_pass
```

# Scheduling and cron issues

The default docker-compose deployment uses cron container.<br>
Problem is it does not work, so Ofelia is used.<br>
[Here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/ofelia)
is guide how to set it up.

Bellow is Ofelia's config file for discovery and ping check of live hosts.

`config.ini`
```ini
[job-exec "phpipam ping"]
schedule = @every 10m
container = phpipam-web
command = /usr/bin/php /phpipam/functions/scripts/pingCheck.php

[job-exec "phpipam discovery"]
schedule = @every 25m
container = phpipam-web
command = /usr/bin/php /phpipam/functions/scripts/discoveryCheck.php
```

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
ipam.{$MY_DOMAIN} {
    reverse_proxy phpipam-web:80
}
```

# First run

![logo](https://i.imgur.com/W7YhwqK.jpg)


* New phpipam installation
* Automatic database installation
* MySQL username: root
* MySQL password: my_secret_mysql_root_pass

# Update

[Watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower)
updates the image automatically.

Manual image update:

- `docker-compose pull`<br>
- `docker-compose up -d`<br>
- `docker image prune`

# Backup and restore

#### Backup

Using [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the entire directory.
  
#### Restore

* down the homer container `docker-compose down`<br>
* delete the entire homer directory<br>
* from the backup copy back the homer directory<br>
* start the container `docker-compose up -d`
