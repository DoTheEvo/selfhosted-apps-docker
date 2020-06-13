# UniFi Controller

###### guide-by-example

![logo](https://i.imgur.com/xm6yo3I.png)

# Purpose & Overview

Ubiquiti managment utility for wifi access points and other hardware.<br>

* [Official site](https://www.ui.com/software/)
* [Manual](https://dl.ui.com/guides/UniFi/UniFi_Controller_V5_UG.pdf)
* [linuxserver github](https://github.com/linuxserver/docker-unifi-controller)

UniFi is a web based managment software for Ubiquiti devices.</br>
It is written in Java, utilizing the Spring Framework
and using MongoDB as a database.

Docker image used here is provided by [linuxserver.io](https://www.linuxserver.io/)

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── unifi/
            ├── config/
            ├── .env
            └── docker-compose.yml
```

* `config/` - a directory where unifi stores its coniguration data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker
  how to run the containers

You only need to provide the files.</br>
The directory is created by docker compose on the first run.

# docker-compose

`docker-compose.yml`
```yml
version: "2.1"
services:
  unifi-controller:
    image: linuxserver/unifi-controller:LTS
    container_name: unifi
    hostname: unifi
    restart: unless-stopped
    env_file: .env
    ports:
      - 3478:3478/udp
      - 10001:10001/udp
      - 8080:8080
      - 8081:8081
      - 8443:8443
      - 8843:8843
      - 8880:8880
      - 6789:6789
    volumes:
      - ./config:/config
```

`.env`
```bash
# GENERAL
TZ=Europe/Bratislava

#LINUXSERVER.IO
PUID=1000
PGID=1000
MEM_LIMIT=1024M #optional
```

# Configuration

For adoption of APs when the controller runs on docker network:

* *Settings > Controller > Controller Settings*<br>
  `Controller Hostname/IP` **set to the IP of the docker host**,<br>
  assuming it is on the same network as the APs
*  **check** `Override inform host with controller hostname/IP`

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

* down the unifi container `docker-compose down`</br>
* delete the entire unifi directory</br>
* from the backup copy back the unifi directory</br>
* start the container `docker-compose up -d`
