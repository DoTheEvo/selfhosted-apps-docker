# Homer in docker

###### guide by example

![logo](https://i.imgur.com/NSZ1DTH.png)

# Purpose

Homepage.

* [Github](https://github.com/bastienwirtz/homer)
* [DockerHub image used](https://hub.docker.com/r/b4bz/homer)

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── homer/
            ├── assets/
            ├── .env
            ├── docker-compose.yml
            └── config.yml
```

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
      - ./config.yml:/www/config.yml
      - ./assets/:/www/assets

networks:
  default:
    external:
      name: $DEFAULT_NETWORK
```

`.env`
```bash
# GENERAL
MY_DOMAIN=blabla.org
DEFAULT_NETWORK=caddy_net
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

Homepage is configured in `config.yml` file.

`config.yml`
```yml
title: "Homepage"
subtitle: "Homer"
logo: "assets/homer.png"
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
        url: "https://book.blabla.org"
      - name: "Bitwarden"
        logo: "/assets/tools/bitwarden.png"
        subtitle: "Password Manager"
        url: "https://passwd.blabla.org"
      - name: "Nextcloud"
        logo: "/assets/tools/nextcloud.png"
        subtitle: "File Sync & Share"
        url: "https://nextcloud.blabla.org"
  - name: "Monitoring"
    icon: "fas fa-heartbeat"
    items:
      - name: "Prometheus + Grafana"
        logo: "/assets/tools/grafana.png"
        subtitle: "Metric analytics & dashboards"
        url: "https://grafana.blabla.org"
      - name: "Portainer"
        logo: "/assets/tools/portainer.png"
        subtitle: "Docker Manager"
        url: "https://portainer.blabla.org"
```

![look](https://i.imgur.com/hrggtcZ.png)

# Update

  * [watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower) updates the image automaticly

  * manual image update</br>
    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`

# Backup and restore

  * **backup** using [BorgBackup setup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
  that makes daily snapshot of the entire directory
    
  * **restore**</br>
    copy config.yml and assets directory from a borg repository to a freshly spin container
