# Syncthing

###### guide-by-example

![logo](https://i.imgur.com/Vgtn1FM.png)

# Purpose & Overview

Synchronize folders between devices.<br>

* [Official](https://syncthing.net/)
* [Github](https://github.com/syncthing/syncthing)

Simple and elegant solution for Synchronizing folders.<br>
Clients are installed on devices, and paired using the Syncthing servers.
There are Windows, MacOs, Linux, Android clients, and 3rd party Möbius Sync for iOS.

Written in Go.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── syncthing/
            ├── 🗋 .env
            └── 🗋 docker-compose.yml
```              
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the container

# Compose

`docker-compose.yml`
```yml
services:

  syncthing:
    image: syncthing/syncthing
    container_name: syncthing
    hostname: syncthing
    restart: unless-stopped
    env_file: .env
    volumes:
      - /mnt/mirror/syncthing:/var/syncthing
    ports:
      - 8384:8384 # Web UI
      - 22000:22000/tcp # TCP file transfers
      - 22000:22000/udp # QUIC file transfers
      - 21027:21027/udp # Receive local discovery broadcasts
  
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

# SYNCTHING
PUID=1000
PGID=1000
```

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).

`Caddyfile`
```php
sync.{$MY_DOMAIN} {
  reverse_proxy syncthing:8384
}
```

# First run

![webgui](https://i.imgur.com/ywdYeU2.png)

visit the webgui, setup username and password in settings > GUI.

* intall sync on other devices
* add folders, confirm them on webgui

sync should just start.


# Trouble shooting

# Update

Manual image update:

- `docker compose pull`</br>
- `docker compose up -d`</br>
- `docker image prune`

