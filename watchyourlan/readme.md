# WatchYourLAN

###### guide-by-example

![pic](https://i.imgur.com/YDDcvVg.png)

# Purpose & Overview

Monitor LAN with regular IP scans.<br>

* [Github](https://github.com/aceberg/WatchYourLAN)

Simple webgui ip scanner with notification when new unknown MAC address appears.

Backend is written in Go.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── watchyourlan/
            ├── 🗋 .env
            └── 🗋 docker-compose.yml
```              
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the container

# Compose

Of note is the `network_mode` being set to `host`,
which means that the container shares the IP with the docker-host
and is on the docker-host network, likely the main netowork,
not some virtual docker network.

`docker-compose.yml`
```yml
services:

  watchyourlan:
    image: aceberg/watchyourlan
    container_name: watchyourlan
    hostname: watchyourlan
    network_mode: host
    env_file: .env
    restart: unless-stopped
    volumes:
      - ./watchyourlan_data:/data     
```

`.env`
```bash
# GENERAL
TZ=Europe/Bratislava

IFACE="ens33"
GUIIP: "10.0.19.4"
GUIPORT="8840"
THEME="darkly"
```

To get variables `IFACE` and `GUIIP` for the `.env` file,
ssh to docker-host and `ip r`

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).

Because of the container running in a host network mode, the IP of the docker-host
is used instead of just some container hostname.

`Caddyfile`
```php
lan.{$MY_DOMAIN} {
  reverse_proxy 10.0.19.4:8840
}
```

# Notifications

WatchYourLAN uses [Shoutrrr](https://containrrr.dev/shoutrrr/v0.5/services/generic/)
for notifications.<br>
If using [ntfy like me](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal),
one just uses generic webhook notation of shoutrrr.

In Config:

* Shoutrrr URL: `generic+https://ntfy.example.com/LAN_home`

# Trouble shooting

# Update

Manual image update:

- `docker compose pull`</br>
- `docker compose up -d`</br>
- `docker image prune`

