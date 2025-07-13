# Mail-Archiver

###### guide-by-example

<!-- ![logo](https://i.imgur.com/RpFC0Rg.png) -->

# Purpose & Overview

 IMAP email archiving system with web gui managment.

* [Github](https://github.com/s1t5/mail-archiver)

Written in C# for backend and postgres for database.
A very new project but looks super promising.<br>

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── mail-archiver/
            ├── 🗁 mailarchiver_database/
            ├── 🗋 .env
            └── 🗋 compose.yml
```

* `mailarchiver_database` - contains the database data, including all emails and attachments
* `.env` - the file containing environment variables for docker compose
* `compose.yml` - the compose file that defines how to run the containers

Only the two files are required.<br>
The directories are created on the first run.

# Compose

Some changes from [the official](https://github.com/s1t5/mail-archiver?tab=readme-ov-file#%EF%B8%8F-installation)
compose.
* env variables are moved to the `.env` file
* reverse proxy is expected so the ports are only exposed(documented),
  not mapped to the host
* hostname and container name are added
* renamed services to have more clear name<br>
  which required to also change the connection string variable,
  replacing host `postgres` with `mailarchiver-db`
* changed bind mount folder name
* network is set

`compose.yml`
```yml
services:
  mailarchiver-app:
    image: s1t5/mailarchiver:latest
    container_name: mailarchiver-app
    hostname: mailarchiver-app
    restart: unless-stopped
    env_file: .env
    expose:
      - "5000"
    depends_on:
      mailarchiver-db:
        condition: service_healthy

  mailarchiver-db:
    image: postgres:17-alpine
    container_name: mailarchiver-db
    hostname: mailarchiver-db
    restart: unless-stopped
    env_file: .env
    expose:
      - "5432"
    volumes:
      - ./mailarchiver_database:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U mailuser -d MailArchiver"]
      interval: 300s
      timeout: 10s
      retries: 3
      start_period: 30s

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

# Database Connection
ConnectionStrings__DefaultConnection=Host=mailarchiver-db;Database=MailArchiver;Username=mailuser;Password=masterkey;

# Authentication Settings
Authentication__Enabled=true
Authentication__Username=admin
Authentication__Password=secure123!
Authentication__SessionTimeoutMinutes=60
Authentication__CookieName=MailArchiverAuth

# MailSync Settings
MailSync__IntervalMinutes=15
MailSync__TimeoutMinutes=60
MailSync__ConnectionTimeoutSeconds=180
MailSync__CommandTimeoutSeconds=300

# BatchRestore Settings
BatchRestore__AsyncThreshold=50
BatchRestore__MaxSyncEmails=150
BatchRestore__MaxAsyncEmails=50000
BatchRestore__SessionTimeoutMinutes=30
BatchRestore__DefaultBatchSize=50

# Npgsql Settings
Npgsql__CommandTimeout=600

# POSTGRES
POSTGRES_DB=MailArchiver
POSTGRES_USER=mailuser
POSTGRES_PASSWORD=masterkey

```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```php
mailarchiver.{$MY_DOMAIN} {
  reverse_proxy mailarchiver-app:5000
}
```

# First run

Login with the credentials set in the `.env` file

# gmail

* 2factorAuth needs to be fulyl enabled and set
* [https://myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)<br>
  create app password

# Trouble shooting


# Update

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

It is **strongly recommended** to now add current **tags** to the images in the compose.<br>
Tags will allow you to easily return to a working state if an update goes wrong.


# Backup and restore

#### Backup

  
#### Restore


# Backup of just user data


#### Backup script


#### Cronjob - scheduled backup

# Restore the user data

