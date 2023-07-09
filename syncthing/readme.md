# Syncthing

###### guide-by-example

![logo](https://i.imgur.com/Vgtn1FM.png)

# Purpose & Overview

Synchronize folders between devices.<br>

* [Official](https://syncthing.net/)
* [Github](https://github.com/syncthing/syncthing)

Simple and elegant solution for Synchronizing folders and nothing else.<br>
Clients are installed on the devices, and then added to the syncthing server.

Written in Go.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── syncthing/
            └── 🗋 docker-compose.yml
```              
* `docker-compose.yml` - a docker compose file, telling docker how to run the container

# Compose

Of note is use of `network_mode: host` as the official documentation
recommends.
What it means is that the container is running straight on docker host IP,
is solely in charge of ports it has inernaly defined.

`docker-compose.yml`
```yml
services:

  syncthing:
    image: syncthing/syncthing
    container_name: syncthing
    hostname: syncthing
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - /mnt/mirror/syncthing:/var/syncthing
    network_mode: host
    ports:
      - 8384:8384 # Web UI
      - 22000:22000/tcp # TCP file transfers
      - 22000:22000/udp # QUIC file transfers
      - 21027:21027/udp # Receive local discovery broadcasts
```

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).

Since using the host network_mode caddy can't use hostname as it wont resolve,
so docker host IP is just used straight up, with the port for web gui.

`Caddyfile`
```php
sync.{$MY_DOMAIN} {
  reverse_proxy 10.0.19.4:8384
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

