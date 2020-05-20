# Homer in docker

###### guide-by-example

![logo](https://i.imgur.com/NSZ1DTH.png)

# Purpose

Homepage.

* [Github](https://github.com/bastienwirtz/homer)
* [DockerHub image used](https://hub.docker.com/r/b4bz/homer)

Homer is a simple static web page, configured using a yaml file.</br>
The docker image uses darkhttpd simple web server on alpine linux.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── homer/
            ├── assets/
            │   └── tools/
            ├── .env
            ├── docker-compose.yml
            └── config.yml
```

* `assets/` - a directory containing icons and other directories with icons
* `.env` - a file containing environmental variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to build the container
* `config.yml` - homer's configuration file bind mounted in to the container

All files and folders need to be provided.</br>
`assets` direcotry is part of this repo.

# docker-compose

`docker-compose.yml`
```yml
version: "2"
services:

  homer:
    image: b4bz/homer:latest
    container_name: homer
    hostname: homer
    restart: unless-stopped
    volumes:
      - ./config.yml:/www/config.yml:ro
      - ./assets/:/www/assets:ro

networks:
  default:
    external:
      name: $DOCKER_MY_NETWORK
```

`.env`
```bash
# GENERAL
MY_DOMAIN=example.com
DOCKER_MY_NETWORK=caddy_net
TZ=Europe/Bratislava
```

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
{$MY_DOMAIN} {
    reverse_proxy homer:8080
}
```

# Config

Homer in this `config.yml` file.</br>
This one is based on the example from
the [github](https://github.com/bastienwirtz/homer).


`config.yml`
```yml
title: "Homepage"
subtitle: "Homer"
logo: "assets/logo.png"
# icon: "fas fa-skull-crossbones"
footer: '<p>less boring look with a footer</p>'

# Optional navbar
links:
  - name: "Font Awesome Icons Galery"
    icon: "fab fa-fort-awesome"
    url: "https://fontawesome.com/icons?d=gallery"
  - name: "Reddit SelfHosted"
    icon: "fab fa-reddit"
    url: "https://www.reddit.com/r/selfhosted/"

# First level array represent a group
# Single service with an empty name if not using groups
services:
  - name: "Main"
    icon: "fab fa-docker"
    items:
      - name: "Bookstack"
        logo: "/assets/tools/bookstack.png"
        subtitle: "Notes and Documentation"
        url: "https://book.example.com"
      - name: "Bitwarden"
        logo: "/assets/tools/bitwarden.png"
        subtitle: "Password Manager"
        url: "https://passwd.example.com"
      - name: "Nextcloud"
        logo: "/assets/tools/nextcloud.png"
        subtitle: "File Sync & Share"
        url: "https://nextcloud.example.com"
  - name: "Monitoring"
    icon: "fas fa-heartbeat"
    items:
      - name: "Prometheus + Grafana"
        logo: "/assets/tools/grafana.png"
        subtitle: "Metric analytics & dashboards"
        url: "https://grafana.example.com"
      - name: "Portainer"
        logo: "/assets/tools/portainer.png"
        subtitle: "Docker Manager"
        url: "https://portainer.example.com"
```

![look](https://i.imgur.com/hrggtcZ.png)

# Update

[Watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower)
updates the image automatically.

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

# Backup and restore

#### Backup

Using [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the entire directory.
  
#### Restore

* down the homer container `docker-compose down`</br>
* delete the entire homer directory</br>
* from the backup copy back the homer directory</br>
* start the container `docker-compose up -d`
