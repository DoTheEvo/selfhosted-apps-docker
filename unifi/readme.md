# UniFi Controller

###### guide-by-example

![logo](https://i.imgur.com/xm6yo3I.png)

# Purpose & Overview

Ubiquiti managment software for wifi access points and other ubiquiti hardware.<br>

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
services:
  unifi:
    image: linuxserver/unifi-controller
    container_name: unifi
    hostname: unifi
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./config:/config
    ports:
      - 8443:8443
      - 3478:3478/udp
      - 10001:10001/udp
      - 8080:8080
      - 1900:1900/udp #optional
      - 8843:8843 #optional
      - 8880:8880 #optional
      - 6789:6789 #optional
      - 5514:5514/udp #optional

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

#LINUXSERVER.IO
PUID=1000
PGID=1000
MEM_LIMIT=1024
MEM_STARTUP=1024
```

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
unifi.{$MY_DOMAIN} {
        encode gzip
        reverse_proxy unifi:8443 {
                transport http {
                        tls
                        tls_insecure_skip_verify
                }
        }
}
```

# Adoption

The controller might see your APs during initial setup,
but it can not adopt them before you set your docker host IP
as `Override Inform Host`.

* *Settings > System > Other Configuration*<br>
  `Override Inform Host` check the Enable checbox<br>
* enter docker-host IP
* adopt devices

# Some Settings

* Old interface > Wifi > advanced settings > disable "High Performance Devices"<br>
  When enabled it forces devices to ignore 2ghz band which obviously causes problems at range. 
  Fucking monstrous stupidity.
* DTIM sets to 3 for [apple devices](https://www.sniffwifi.com/2016/05/go-to-sleep-go-to-sleep-go-to-sleep.html)


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
