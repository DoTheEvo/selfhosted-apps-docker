# Zammad in docker

###### guide-by-example

![logo](https://i.imgur.com/cuL1Vm7.png)

# Purpose & Overview

Ticketing system.

* [Official site](https://zammad.org/screenshots)
* [Github](https://github.com/zammad/zammad)
* [DockerHub](https://hub.docker.com/r/zammad/zammad-docker-compose)

Zammad is a modern, open source, good looking web base
helpdesk/customer support system.<br>
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

I prefer to store backups as bind mounts rather than volumes,
as volumes can get destroyed by a simple `docker-compose down -v`
that can popup in terminal history if used before, and be run by accident.

So here we override backup locations and join it to reverse proxy network.<br>

`docker-compose.override.yml`
```yml
version: '2'
services:

  zammad-nginx:
    ports:
      - "8080:8080"
    environment:
    - NGINX_SERVER_SCHEME=https
    - RAILS_TRUSTED_PROXIES=['127.0.0.1', '::1', 'caddy']

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

Part of solving the situation when zammad is behind a proxy is accounting for
a security measure where cookies are not accepted on a http connection
by zammad's ngnix server.
The secure TLS connection ends at caddy
and then the communication between caddy and zammad's ngnix server is
just plain http.<br>
This will cause **CSRF token verification failed** when trying to log in to zammad.

The way the [issue](https://github.com/zammad/zammad/issues/2829) is solved
is adding two env variables to the compose override file, under nginx container.<br>
These tell zammad's nginx server to use `https` scheme for X-Forwarded-Proto header,
and to trust proxy server with hostname `caddy`.

```yml
environment:
  - NGINX_SERVER_SCHEME=https
  - RAILS_TRUSTED_PROXIES=['127.0.0.1', '::1', 'caddy']
```

This is just explanation, the lines are included in the override file.

# First run

* Setup admin email and password.
* Organization name and domain - System URL.
* Email notifications, using smpt. It needs domain set,
  wont work with just localhost.
* Setup email channel.<br>
  This should be an email address where any email received
  will create an unassigned ticket in zammad and sender will be added to users.<br>
  But even if it is not planned to be in use,
  it is [required](https://github.com/zammad/zammad/issues/2352) for sending
  email notifications using triggers. 

---

![interface-pic](https://i.imgur.com/zstwSqN.png)

Basic setup and use

* Zammad does not really like to show dropdown menus, whenever you are filling
  up some text field where various entries should popup, like list of organizations,
  you need to write first two characters for something to show up.
* Create an organization.
* Create a user as memember of this org. Give them email.
* Check if there is a group in groups and if it has assigned email.
* Test if creating a ticket will send notifications as expected.
* Check triggers for lot of relevant goodies.

# Update

While [Watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower)
might work for containers of the stack,
might be preferable to just do backup and restore in a new git clone.

# Backup and restore

#### Backup

Out of the box a container doing daily backups is running.
Creating two files - backup of the database, and backup of the zammad files.
By default these are saved to a docker volume, but in override it has been changed
to a bind mount in the zammad-docker-compose directory.

Additionaly using [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the entire \~/docker directory will keep backups safe.<br>

  
#### Restore

* shutdown the stack and remove all named volumes
  `docker-compose down -v`
  Warning, by default the backups are in one of these volumes
  be sure you have them somewhere safe before using `-v`
* delete entire `zammad-docker-compose` directory containing the compose file and shit
* git clone the repo,<br>
  edit the override file and env file for your setup
* start it all up
  `docker-compose up -d` and wait few minutes till everything finishes,<br>
  ctop, select nginx container, arrow left shows the log,<br>
  should be at - "starting nginx..."
* stop it all - `docker-compose down`
* extract the database backup<br>
  `gzip -dk 20210605053326_zammad_db.psql.gz`<br>
  rename it to something shorter like backup_db.psql<br>
  place it in to `/var/lib/docker/volumes/zammad-docker-compose_zammad-postgresql-data/_data/`<br>
  I use nnn file manager as root.
* start zammad-postgresql container
  `docker-compose up -d zammad-postgresql`
* exec in to it `docker exec -it zammad-docker-compose_zammad-postgresql_1 bash`<br>
  test you can connect to the database `psql -U zammad`<br>
  quit `\q`<br>
  back in bash, drop the existing database `dropdb zammad_production -U zammad`<br>
  create a new empty database `createdb zammad_production -U zammad`<br>
  restore data from backup in to it<br>
  `psql zammad_production < /var/lib/postgresql/data/backup_db.psql -U zammad`<br>
  if you get some errors about already existing, you forgot to drop the database
* exit and down the container
  `docker-compose down`
* on docker host navigate to `/var/lib/docker/volumes/zammad-docker-compose_zammad-data/_data/`
  and delete everything there
* extract zammad data somewhere<br>
  `tar -xvpf 20210605053326_zammad_files.tar.gz`<br>
  copy content of opt/zammad/ containing directories - app, bin, config,...<br>
  in to /var/lib/...  where you previously deleted this stuff<br>
  again, I use nnn file manager as root.
* start everything<br>
  `docker-compose up -d`
* exec to rake container and run `rake searchindex:rebuild` to get search working again


In case something is not working right, check nginx logs.
Depending on how you copied the stuff, there could be ownership issue
so in nginx check /opt/zammad and its content with `ls -al`,
if its owned by zammad user.
if its root use `chown -R zammad:zammad /opt/zammad`
and down and up the stack.
