# Portainer in docker

###### guide by example

### purpose

User friendly overview of running containers.

### files and directory structure

  ```
  /home
  └── ~
      └── docker
          └── portainer
              ├── 🗁 portainer_data
              ├── 🗋 .env
              └── 🗋 docker-compose.yml
  ```

### docker-compose

  `docker-compose.yml`

  ```
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

  ```
  # GENERAL
  MY_DOMAIN=blabla.org
  DEFAULT_NETWORK=caddy_net
  TZ=Europe/Prague
  ```

### reverse proxy

  caddy v2 is used,
  details [here](https://github.com/DoTheEvo/Caddy-v2-examples)

  `Caddyfile`
  ```
  {
      # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
  }

  portainer.{$MY_DOMAIN} {
      reverse_proxy {
          to portainer:9000
      }
  }
  ```

### update

  * image update using docker compose 

    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`
