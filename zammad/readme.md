# Zammad in docker

###### guide-by-example

![logo](https://i.imgur.com/cuL1Vm7.png)

# Purpose & Overview

Ticketing system.

* [Official site](https://zammad.org/)
* [Github](https://github.com/zammad/zammad)
* [DockerHub](https://hub.docker.com/r/zammad/zammad-docker-compose)

Zammad is a modern, open source, good looking web base
helpdesk/customer support system.

Written in Ruby. This deployment uses PostgreSQL for database
powered by elasticsearch, with nginx for web server.

# Requirements

Elastisearch requires higher limit of maximum virtual address space for memory mapping.<br>
To check the current limit:

`sysctl vm.max_map_count`

Default likely being \~65k.

To set it permanently to \~260k as required by elasticsearch:

* For arch linux, it means creating `elasticsearch.conf` in `/usr/lib/sysctl.d/`,
containing the line that sets the desired  max map count:

  `/usr/lib/sysctl.d/elasticsearch.conf`
  ```
  vm.max_map_count=262144
  ```
  This is done automatically if one would install elasticsearch package on docker host.

* For debian based distros you put the line in `/etc/sysctl.conf`

This is done on the docker host.<br>
Afterwards, reboot and check again with `sysctl vm.max_map_count`

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── zammad-docker-compose/
            ├── ..lots of files and folders..
            ├── .env
            └── docker-compose.override.yml
```

* `.env` - a file containing environment variables for docker compose
* `docker-compose.override.yml` - an override of the  the default compose file

Use git clone to download the latest zammad-docker-compose repo from github.

`git clone https://github.com/zammad/zammad-docker-compose.git`

This brings a lot of files and folders and everything is pre-prepared.<br>

# docker-compose

We are not touching the compose file.<br>
Changes are done only to the `docker-compose.override.yml` and the `.env` file.

In this case we override port, network and backup locations.<br>
I prefer backups as bind mounts rather than volumes,
which can get destroyed by simple `docker-compose down -v`
that can popup in terminal history, if used before, and be run by accident.

`docker-compose.override.yml`
```yml
version: '2'
services:

  zammad-nginx:
    ports:
      - "8080:8080"

  zammad-backup:
    volumes:
      - ./zammad-backup:/var/tmp/zammad
      - ./zammad-data:/opt/zammad

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

IMAGE_REPO=zammad/zammad-docker-compose
POSTGRES_PASS=zammad
POSTGRES_USER=zammad
RESTART=always
# don't forget to add the minus before the version
VERSION=-4.0.0-25
```

**All containers must be on the same network**.<br>
Which is named in the `.env` file.<br>
If one does not exist yet: `docker network create caddy_net`



# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).<br>

`Caddyfile`
```
ticket.{$MY_DOMAIN} {
    reverse_proxy zammad-nginx:8080
}
```

# First run

* Setup admin email and password.
* Organization name and domain - System URL.
* Email notifications, using smpt. It needs domain set,
  wont work with just localhost
* Setup email channel.
  This should be an email address where any email received
  will create an unassgnied ticket in zammad and sender will be added to users.<br>
  But even if it is not planned to use,
  it is [required](https://github.com/zammad/zammad/issues/2352) for sending
  email notifications using triggers. 

---

![interface-pic](https://i.imgur.com/zstwSqN.png)

Basic setup and use

* Zammad does not really like to show dropdown menus, whenever you are filling
  information that should already be there,
  you need to write first two characters for something to pop up.
* Create an organization.
* Create a user as memember of this org. Give them email.
* Check if there is a group in groups and if it has assigned email.
* Test if creating a ticket will send notifications as expected.
* Check triggers for lot of relevant options.

# Update

While [Watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower)
might work for containers fine.
I might prefer manual update, where it's basicly delete all, git clone new, and restore backups.

# Backup and restore

#### Backup

Out of the box a container doing daily backups is running.
By default these are saved to a docker volume, but in override it has been changed
to bind mount in the zammad directory.

So using [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the entire directory will keep backups safe.<br>

  
#### Restore

* shutdown the stack and remove all named volumes
  `docker-compose down -v`
  Warning, by default the backups are in one of these volumes
  be sure you cope them somewhere else before using `-v`
* delete entire zammad directory containing the compose file and shit
* git clone the repo for new installation
* start it up,
  `docker-compose up -d`
  wait few minutes till everything finishes,
  ctop, select nginx container, arrow left shows the log,
  should be at - 'starting nginx...'
* stop it all - `docker-compose down`
* extract the database backup from `20210515183647_zammad_db.psql.gz`,
  `gzip -dk 20210605053326_zammad_db.psql.gz`
  rename it to something shorter like backup_db.psql
  place it in to `/var/lib/docker/volumes/zammad-docker-compose_zammad-postgresql-data/_data/`
* start zammad-postgresql container
  `docker-compose up -d zammad-postgresql`
* exec in to it `docker exec -it zammad-docker-compose_zammad-postgresql_1 bash`
* test you can connect to the database `psql -U zammad`
  quit `\q`
* back in bash, drop the existing database `dropdb zammad_production -U zammad`
* create new empty database `createdb zammad_production -U zammad`
* restore data from backup in to it 
  `psql zammad_production < /var/lib/postgresql/data/backup_db.psql -U zammad`
  if you get some errors about already existing, you forgot to drop the database
* exit and down the container
  `docker-compose down`
* on docker host navigate to `/var/lib/docker/volumes/zammad-docker-compose_zammad-data/_data/`
  and delete everything there
* extract 20210515183647_zammad_files.tar somewhere
  `tar -xvpf 20210605053326_zammad_files.tar.gz`
  copy content of opt/zammad/ containing - app, bin, config,...
  in to /var/lib/...  where you previously deleted this stuff
* start everything
* exec to rake container and run `rake searchindex:rebuild` to fix searching


in case something is not working righ, check nginx logs,
depending on how you copied the stuff, there could be ownership issue
so in nginx check /opt/zammad and its content with `ls -al`
if its owned by zammad user.
if its root use `chown -R zammad:zammad /opt/zammad`
