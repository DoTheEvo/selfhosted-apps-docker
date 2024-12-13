# qBittorrent in docker

###### guide-by-example

![logo](https://i.imgur.com/lL6Jucn.png)

# Purpose & Overview

WORK IN PROGRESS<br>
WORK IN PROGRESS<br>
WORK IN PROGRESS<br>

Torrents downloader.

* [Official site](https://www.qbittorrent.org/)
* [Github](https://github.com/linuxserver/docker-qbittorrent)
* [DockerHub](https://hub.docker.com/r/linuxserver/qbittorrent/)

qBittorrent is a cross-platform free and open-source BitTorrent client.<br>
The interface is clone of the popular uTorrent.<br>
Major feature is the build in torrent search on various trackers.

Written mostly in C++, using libtorrent under the hood.

# Files and directory structure

```
/mnt/
└── bigdisk/
    └── torrents/
/home/
└── ~/
    └── docker/
        └── qbittorrent/
            ├── qbittorrent-config/
            ├── .env
            └── docker-compose.yml
```

* `/mnt/bigdisk/...` - a mounted storage share
* `qbittorrent-config/` - configuration 
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the files.</br>
The directories are created by docker compose on the first run.

# docker-compose

Dockerhub linuxserver/bookstack 
[example compose.](https://hub.docker.com/r/linuxserver/bookstack)

`docker-compose.yml`
```yml
services:

  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent
    container_name: qbittorrent
    hostname: qbittorrent
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./qbittorrent-config:/config
      - /mnt/smalldisk/torrents:/downloads
    expose:
      - 8080
    ports:
      - 6881:6881
      - 6881:6881/udp
      - 8080:8080

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true
```

`.env`
```bash
# GENERAL
MY_DOMAIN=example.com
DOCKER_MY_NETWORK=caddy_net
TZ=Europe/Bratislava

WEBUI_PORT=8080
PUID=1000
PGID=1000
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

# Reverse proxy

Caddy is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
q.{$MY_DOMAIN} {
    reverse_proxy qbittorrent:8080
}
```

# First run

The administrator username and a temporary password can be found by running `docker logs qbittorrent`

---

![interface-pic](https://i.imgur.com/cN1GUZw.png)


# Specifics of my setup

* no long term use yet
* no gpu, so no experience with hw transcoding
* media files are stored and shared on trunas scale VM
 and mounted to the docker host using systemd mounts,
 instead of fstab or autofs.

  `/etc/systemd/system/mnt-bigdisk.mount`
  ```ini
  [Unit]
  Description=12TB truenas mount

  [Mount]
  What=//10.0.19.19/Dataset-01
  Where=/mnt/bigdisk
  Type=cifs
  Options=ro,username=ja,password=qq,file_mode=0700,dir_mode=0700,uid=1000
  DirectoryMode=0700

  [Install]
  WantedBy=multi-user.target
  ```

   `/etc/systemd/system/mnt-bigdisk.automount`
  ```ini
  [Unit]
  Description=myshare automount

  [Automount]
  Where=/mnt/bigdisk

  [Install]
  WantedBy=multi-user.target
  ```

  automount on boot - `sudo systemctl start mnt-bigdisk.automount`

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

* down the bookstack containers `docker-compose down`</br>
* delete the entire bookstack directory</br>
* from the backup copy back the bookstack directory</br>
* start the containers `docker-compose up -d`

# Backup of just user data

Users data daily export using the
[official procedure.](https://www.bookstackapp.com/docs/admin/backup-restore/)</br>
For bookstack it means database dump and backing up several directories
containing user uploaded files.

Daily [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup) run
takes care of backing up the directories.
So only database dump is needed.</br>
The created backup sqlite3 file is overwritten on every run of the script,
but that's ok since borg is making daily snapshots.

#### Create a backup script

Placed inside `bookstack` directory on the host

`bookstack-backup-script.sh`
```bash
#!/bin/bash

# CREATE DATABASE DUMP, bash -c '...' IS USED OTHERWISE OUTPUT > WOULD TRY TO GO TO THE HOST
docker container exec bookstack-db bash -c 'mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $MYSQL_DIR/BACKUP.bookstack.database.sql'
```

the script must be **executable** - `chmod +x bookstack-backup-script.sh`

#### Cronjob

Running on the host, so that the script will be periodically run.

* `su` - switch to root
* `crontab -e` - add new cron job</br>
* `0 22 * * * /home/bastard/docker/bookstack/bookstack-backup-script.sh`</br>
  runs it every day [at 22:00](https://crontab.guru/#0_22_*_*_*) 
* `crontab -l` - list cronjobs to check

# Restore the user data

Assuming clean start, first restore the database before running the app container.

* start only the database container: `docker-compose up -d bookstack-db`
* copy `BACKUP.bookstack.database.sql` in `bookstack/bookstack-db-data/`
* restore the database inside the container</br>
  `docker container exec --workdir /config bookstack-db bash -c 'mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < BACKUP.bookstack.database.sql'`
* now start the app container: `docker-compose up -d`
* let it run so it creates its file structure
* down the containers `docker-compose down`
* in `bookstack/bookstack-data/www/`</br>
  replace directories `files`,`images`,`uploads` and the file `.env`</br>
  with the ones from the BorgBackup repository 
* start the containers: `docker-compose up -d`
* if there was a major version jump, exec in to the app container and run `php artisan migrate`</br>
  `docker container exec -it bookstack /bin/bash`</br>
  `cd /var/www/html/`</br>
  `php artisan migrate`

Again, the above steps are based on the 
[official procedure.](https://www.bookstackapp.com/docs/admin/backup-restore/)
