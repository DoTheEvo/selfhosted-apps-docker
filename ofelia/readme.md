# Ofelia in docker

###### guide-by-example

# Purpose

Scheduling jobs that will be run in docker containers.

* [Github](https://github.com/mcuadros/ofelia)
* [DockerHub image used](https://hub.docker.com/r/mcuadros/ofelia/)

Ofelia is a simple scheduler for docker containers, replacing cron.</br>
Written in go, its binary is running in the background as a daemon,
executing scheduled tasks as set in a simple config file.


# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── ofelia/
            ├── docker-compose.yml
            └── config.ini
```

* `docker-compose.yml` - a docker compose file, telling docker how to run the container
* `config.ini` - ofelia's configuration file bind mounted in to the container

All files need to be provided.

# docker-compose

`docker-compose.yml`
```yml
version: "3"
services:

  ofelia:
    image: mcuadros/ofelia
    container_name: ofelia
    hostname: ofelia
    restart: unless-stopped
    volumes:
      - ./config.ini:/etc/ofelia/config.ini:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
```

# Config

config.ini contains scheduled jobs.</br>
There are several [types](https://github.com/mcuadros/ofelia/blob/master/docs/jobs.md),
but here is just the basic most common use: *job-exec*</br>
which executes command inside an already running container.

`config.ini`
```ini
[job-exec "test1"]
schedule = @every 5m
container = phpipam_phpipam-web_1
command = touch /tmp/bla

[job-exec "test2"]
schedule = @every 1h
container = phpipam_phpipam-mariadb_1
command = touch /tmp/bla

[job-exec "test3"]
schedule = @every 1h30m10s
container = phpipam_phpipam-cron_1
command = touch /tmp/bla
```

# Logging

![logo](https://i.imgur.com/5SgWE0I.png)

Docker containers log shows which jobs are active and when they were executed.

But Ofelia has several build in
[logging options.](https://github.com/mcuadros/ofelia#logging)

#### email 

Unfortunetly seems `[global]` section, where email settings would be set once
and then enabled per job is not working.
So either the settings would go
in to `[global]` and be set for every single job, or every job that requires
email logging will have to have all the email settings writen out in full.

`config.ini`
```ini
[job-exec "test1"]
schedule = @every 5m
container = phpipam_phpipam-web_1
command = touch /tmp/zla
smtp-user = apikey
smtp-password = SG.***************************
smtp-host = smtp.sendgrid.net
smtp-port = 465
mail-only-on-error = false
email-to = whoever@example.com
email-from = test@example.com

[job-exec "test2"]
schedule = @every 2m
container = phpipam_phpipam-mariadb_1
command = touch /tmp/zla

```

#### save-folder

Saves result of every job execution in to a file.

By defining `save-folder` path for the job.</br>
The path used should be bind mounted from the host,
for persistence of the data and easier access.

`docker-compose.yml`
```yml
version: "3"
services:

  ofelia:
    image: mcuadros/ofelia
    container_name: ofelia
    hostname: ofelia
    restart: unless-stopped
    volumes:
      - ./config.ini:/etc/ofelia/config.ini:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./logs:/tmp/logs
```

`config.ini`
```ini
[job-exec "test1"]
schedule = @every 5m
container = nginx
command = touch /tmp/example
save-folder = /tmp/logs
```

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
