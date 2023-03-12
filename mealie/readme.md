# Mealie in docker

###### guide-by-example

![logo](https://i.imgur.com/G546d6v.png)

# Purpose & Overview

Recipe cookbook.

* [The official site](https://hay-kot.github.io/mealie/)
* [Github](https://github.com/hay-kot/mealie)
* [DockerHub](https://hub.docker.com/r/hkotel/mealie)

Mealie is a simple, open source, self hosted cookbook.<br>
Written in python and javascript, using Vue framework for frontend.
It stores recipies in plain json as well as sqlite database.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── bookstack/
            ├── 🗁 mealie_data/
            ├── 🗋 .env
            └── 🗋 docker-compose.yml
```

* `mealie_data/` - a directory with persistent data and backups
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

Only the files are required. The directory is created on the first run.

# docker-compose

The official documentation compose example
[here.](https://hay-kot.github.io/mealie/documentation/getting-started/install/#docker-compose-with-sqlite)

`docker-compose.yml`
```yml
services:

  mealie:
    image: hkotel/mealie
    container_name: mealie
    hostname: mealie
    restart: unless-stopped
    env_file: .env
    expose:
      - "80"
    volumes:
      - ./mealie_data/:/app/data

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

# MEALIE
PUID=1000
PGID=1000
RECIPE_PUBLIC=true
RECIPE_SHOW_NUTRITION=true
RECIPE_SHOW_ASSETS=true
RECIPE_LANDSCAPE_VIEW=true
RECIPE_DISABLE_COMMENTS=false
RECIPE_DISABLE_AMOUNT=false
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```php
book.{$MY_DOMAIN} {
    reverse_proxy mealie:80
}
```

# First run

Default login: `changeme@email.com` // `MyPassword`

---

![interface-pic](https://i.imgur.com/Y1VtD0e.png)

# New version incomig

There is a new version in work, v1.0.0 is already in beta5,
but it seems a major changes are introduced and theres not yet feature to
share recipies with people without password.

# Update

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

It is **strongly recommended** to now add current **tags** to the images in the compose.<br>
Tags will allow you to easily return to a working state if an update goes wrong.

# Backup and restore

#### Backup

Using [kopia](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/kopia_backup)
or [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
to make daily snapshot of the entire docker directory.
  
#### Restore

* down the containers `docker-compose down`</br>
* delete/move/rename the entire project directory</br>
* from the backups copy back the entire project directory</br>
* start the containers `docker-compose up -d`
