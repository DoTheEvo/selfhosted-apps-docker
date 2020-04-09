# Watchtower in docker

###### guide by example

### purpose

Automatic updates of containers.

* [Github](https://github.com/containrrr/watchtower)
* [DockerHub image used](https://hub.docker.com/r/containrrr/watchtower)

### files and directory structure

  ```
  /home
  └── ~
      └── docker
          └── watchtower
              └── 🗋 docker-compose.yml
  ```

### docker-compose

  [scheduled](https://pkg.go.dev/github.com/robfig/cron@v1.2.0?tab=doc#hdr-CRON_Expression_Format)
  to run every saturday at midnight</br>
  no need to be on the same network as other containers, no need .env file</br>

  `docker-compose.yml`

  ```
  version: '3'
  services:
    watchtower:
      image: containrrr/watchtower:latest
      container_name: watchtower
      hostname: watchtower
      restart: unless-stopped
      environment:
        - TZ=Europe/Prague
        - WATCHTOWER_SCHEDULE=0 0 0 * * SAT
        - WATCHTOWER_CLEANUP=true
        - WATCHTOWER_TIMEOUT=30s
        - WATCHTOWER_DEBUG=false
        - WATCHTOWER_INCLUDE_STOPPED=false
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock
  ```

### reverse proxy

  no web interface

### update

  it updates itself
