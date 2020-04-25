# Portainer in docker

###### guide by example

![logo](https://i.imgur.com/QxnuB1g.png)

# Purpose

User friendly overview of running containers.

# Files and directory structure

```
/home
└── ~
    └── docker
        └── portainer
            ├── 🗁 portainer_data
            ├── 🗋 .env
            └── 🗋 docker-compose.yml
```

# docker-compose

`docker-compose.yml`
```yml
version: '2'

services:
  portainer:
    image: portainer/portainer
    container_name: portainer
    hostname: portainer
    command: -H unix:///var/run/docker.sock
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer_data:/data
    environment:
      - TZ

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
TZ=Europe/Prague
```

# reverse proxy

Caddy v2 is used,
details [here](https://github.com/DoTheEvo/Caddy-v2-docker-example-setup).

`Caddyfile`
```
portainer.{$MY_DOMAIN} {
    reverse_proxy portainer:9000
}
```

# Update

  * [watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower) updates the image automaticly

  * manual image update</br>
    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`
