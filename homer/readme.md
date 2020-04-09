# Homer in docker

###### guide by example

### purpose

Homepage.

* [Github](https://github.com/bastienwirtz/homer)
* [DockerHub image used](https://hub.docker.com/r/linuxserver/bookstack)

### files and directory structure

  ```
  /home
  └── ~
      └── docker
          └── homer
              ├── 🗁 assets
              ├── 🗋 .config.yml
              ├── 🗋 .env
              └── 🗋 docker-compose.yml
  ```

### docker-compose

  `docker-compose.yml`

  ```
  version: "2"
  services:
    homer:
      image: b4bz/homer:latest
      container_name: homer
      hostname: homer
      volumes:
        - .config.yml:/www/config.yml
        - ./assets/:/www/assets
      restart: unless-stopped
      expose:
        - "8080"

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
  ```

### reverse proxy

  caddy v2 is used,
  details [here](https://github.com/DoTheEvo/Caddy-v2-examples)

  `Caddyfile`
  ```
  {
      # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
  }

  netdata.{$MY_DOMAIN} {
      reverse_proxy {
          to netdata:80
      }
  }
  ```

### update

  * image update using docker compose 

    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`


