# Audiobookshelf

###### guide-by-example

![logo](https://i.imgur.com/vviMB5v.png)

# Purpose & Overview

WORK IN PROGRESS<br>
WORK IN PROGRESS<br>
WORK IN PROGRESS<br>

Selfhosted audiobook library.

* [Official site](https://www.audiobookshelf.org/)
* [Github](https://github.com/advplyr/audiobookshelf)

Opensource. Able to download the books localy. Written in javascript.

# Client apps 

* android - [audiobookshelf-app](https://github.com/advplyr/audiobookshelf-app)
* ios - [plappa](https://apps.apple.com/us/app/plappa/id6475201956),
  unless [the official one](https://github.com/advplyr/audiobookshelf-app) is out of beta

# Files and directory structure

```
/mnt/
└── bigdisk/
    └── audiobooks/
/home/
└── ~/
    └── docker/
        └── audiobookshelf/
            ├── config/
            ├── metadata/
            ├── .env
            └── compose.yml
```

* `/mnt/bigdisk/...` - a mounted media storage share
* `config/` - persistent configuration
* `metadata/` - metadata 
* `.env` - a file containing environment variables for docker compose
* `compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the two files.</br>
The directories are created by docker compose on the first run.

# compose

Port is only exposed, meaning it's just documentation to know that
it's running on port 80. Reverse proxy is expected so thats why not
really needed opening ports.


`compose.yml`
```yml
services:

  audiobookshelf:
    image: ghcr.io/advplyr/audiobookshelf
    container_name: audiobookshelf
    hostname: audiobookshelf
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./config:/config
      - ./metadata:/metadata
      - /mnt/bigdisk/audiobooks:/mnt/audiobooks
    expose:
      - "80"

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
PUID=1000
PGID=1000
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

# Reverse proxy

Caddy is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
books.{$MY_DOMAIN} {
    reverse_proxy audiobookshelf:80
}
```

# First run


...

# Library organization



# Troubleshooting



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

* down the bookstack containers `docker-compose down`</br>
* delete the entire bookstack directory</br>
* from the backup copy back the bookstack directory</br>
* start the containers `docker-compose up -d`
