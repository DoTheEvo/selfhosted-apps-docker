# Umami


# Purpose & Overview
Self-hosted, private, simple web site analytics with Umami.

* [Github] (https://github.com/umami-software/umami)

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── umami/
            ├── .env
            └── docker-compose.yml
```
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the container

### - Create .env and docker-compose.yml file
`.env`
```
# GENERAL
MY_DOMAIN=example.com
DOCKER_MY_NETWORK=caddy_net

# UMAMI
DATABASE_URL=postgresql://umami:generate_me@db:5432/umami
DATABASE_TYPE=postgresql
# generate a secret with `openssl rand -base64 32`
APP_SECRET=generate_me
# uncomment and change for custom analytics script name 
# TRACKER_SCRIPT_NAME=custom_script_name

# UMAMI DB
POSTGRES_DB=umami
POSTGRES_USER=umami
# generate a password with `openssl rand -base64 32`
POSTGRES_PASSWORD=generate_me
```

`docker-compose.yml`
```yml
---
version: '3'
services:

  umami:
    container_name: umami
    image: ghcr.io/umami-software/umami:postgresql-latest
    ports:
      - "3000:3000"
    env_file: .env
    depends_on:
      db:
        condition: service_healthy
    restart: always

  db:
    container_name: umami-db
    image: postgres:15-alpine
    env_file: .env
    volumes:
      - umami-db-data:/var/lib/postgresql/data
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  umami-db-data:

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true

```

# Reverse proxy

Caddy is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
umami.{$MY_DOMAIN} {
  reverse_proxy umami:3000

  log {
      output file /data/logs/umami_access.log {
          roll_size 20mb
          roll_keep 5
      }
  }
}
```

### - Run it all
Restarting the Caddy container `docker container restart caddy` will kick in the changes. Give Caddy time to get certificates, check `docker logs caddy`.

# First run

Default login: `admin` // `umami`. Go and change the password straight away.

# Trouble shooting

Check umami logs `docker logs umami`.

# Update

[Watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower)
updates the image automatically.

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`
