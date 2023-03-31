# Portainer in docker

###### guide-by-example

![logo](https://i.imgur.com/QxnuB1g.png)

# Purpose

Web GUI for overview and management of docker environment.

* [Official site](https://www.portainer.io)
* [Github](https://github.com/portainer/portainer)
* [DockerHub image used](https://hub.docker.com/r/portainer/portainer-ce/)

Lightweight management web UI, that allows to easily manage
docker containers, networks, volumes, images,... the work.

In my use it is mostly information tool, rather than a management tool.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── portainer/
            ├── portainer_data/
            ├── .env
            └── docker-compose.yml
```

* `portainer_data/` - a directory where portainer stores its peristent data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker
  how to run the containers

You only need to provide the files.</br>
The directory is created by docker compose on the first run.

# docker-compose

`docker-compose.yml`
```yml
services:
  portainer:
    image: portainer/portainer-ce
    container_name: portainer
    hostname: portainer
    command: -H unix:///var/run/docker.sock
    restart: unless-stopped
    env_file: .env
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer_data:/data
    expose:
      - "9443"

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
```

# reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
port.example.com {
  reverse_proxy portainer:9443 {
    transport http {
      tls
      tls_insecure_skip_verify
    }
  }
}
```

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

* down the portainer container `docker-compose down`</br>
* delete the entire portainer directory</br>
* from the backup copy back the portainer directory</br>
* start the container `docker-compose up -d`
