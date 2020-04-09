# Bookstack in docker

###### guide by example

![logo](https://i.imgur.com/qDXwqaU.png)

### Purpose

Documentation and notes.

* [Official site](https://www.bookstackapp.com/)
* [Github](https://github.com/BookStackApp/BookStack)
* [DockerHub image used](https://hub.docker.com/r/linuxserver/bookstack)

### Files and directory structure

  ```
  /home
  └── ~
      └── docker
          └── bookstack
              ├── 🗁 bookstack-data
              ├── 🗁 bookstack-data-db
              ├── 🗁 bookstack-backup
              ├── 🗋 .env
              ├── 🗋 docker-compose.yml
              └── 🗋 bookstack-backup-script.sh
  ```

### docker-compose

  Dockerhub linuxserver/bookstack [example compose.](https://hub.docker.com/r/linuxserver/bookstack)

  `docker-compose.yml`

  ```
  version: "2"
  services:

    bookstack:
      image: linuxserver/bookstack
      container_name: bookstack
      hostname: bookstack
      environment:
        - PUID
        - PGID
        - DB_HOST
        - DB_USER
        - DB_PASS
        - DB_DATABASE
        - APP_URL
      volumes:
        - ./bookstack-data:/config
      restart: unless-stopped
      depends_on:
        - bookstack_db

    bookstack_db:
      image: linuxserver/mariadb
      container_name: bookstack_db
      hostname: bookstack_db
      environment:
        - PUID
        - PGID
        - MYSQL_ROOT_PASSWORD
        - TZ
        - MYSQL_DATABASE
        - MYSQL_USER
        - MYSQL_PASSWORD
      volumes:
        - ./bookstack-data-db:/config
      restart: unless-stopped

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

  # BOOKSTACK
  PUID=1000
  PGID=1000
  DB_HOST=bookstack_db
  DB_USER=bookstack
  DB_PASS=bookstack
  DB_DATABASE=bookstackapp
  APP_URL=https://book.blabla.org

  # BOOKSTACK-MARIADB
  PUID=1000
  PGID=1000
  MYSQL_ROOT_PASSWORD=bookstack
  MYSQL_DATABASE=bookstackapp
  MYSQL_USER=bookstack
  MYSQL_PASSWORD=bookstack
  ```

### reverse proxy

  caddy v2 is used,
  details [here](https://github.com/DoTheEvo/Caddy-v2-examples)

  `Caddyfile`
  ```
  {
      # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
  }

  book.{$MY_DOMAIN} {
      reverse_proxy {
          to bookstack:80
      }
  }
  ```

### update

  * [watchguard]() updates the image automaticly

  * manual image update</br>
    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`

### backup and restore

  * **backup** using [borgbackup setup](https://github.com/DoTheEvo/docker-selfhosted-projects/tree/master/borg_backup)
  that makes daily backup of the entire directory
    
  * **restore**</br>
    down the bookstack containers `docker-compose down`</br>
    delete the entire bookstack directory</br>
    from the backup copy back the bookstack directortory</br>
    start the container `docker-compose up -d`

### Backup of just user data

For additional peace of mind.
Having user-data daily exported using the [official procedure.](https://www.bookstackapp.com/docs/admin/backup-restore/)</br>
For bookstack it means database dump and the content of several directories
containing user uploaded files.
The backup files are overwriten on every run of the script,
but borg backup is backing entire directory in to snapshots, so no need for some keeping-last-X consideration.

  * **database backup**</br>
    script `make_backup.sh` placed in to `bookstack_db` container,
    in to `/config` directory that is bind mounted to the host machine.</br>
    made executable `chmod +x make_backup.sh` inside the container

    - This script creates path `/config/backups-db`</br>
    - deletes all files in the backup path except 30 newest</br>
    - creates new mysqldump using env variables passed from `.env` file</br>

    `make_backup.sh`
    ```
    #!/bin/bash

    # -----------------------------------------------
    NUMB_BACKUPS_TO_KEEP=30
    BACKUP_PATH=/config/backups-db
    BACKUP_NAME=$(date +"%s").bookstack.database.backup.sql
    # -----------------------------------------------

    mkdir -p $BACKUP_PATH

    cd $BACKUP_PATH
    ls -tr | head -n -$NUMB_BACKUPS_TO_KEEP | xargs --no-run-if-empty rm

    mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $BACKUP_PATH/$BACKUP_NAME
    ```

  * **files backup**</br>
    script `make_backup.sh` placed in to `bookstack` container,
    in to `/config` directory that is bind mounted to the host machine.</br>
    made executable `chmod +x make_backup.sh` inside the container

    - This script creates path `/config/backups-files`</br>
    - deletes all files in the backup path except 30 newest</br>
    - creates new archive containing uploaded files</br>

    `make_backup.sh`
    ```
    #!/bin/bash

    # -----------------------------------------------
    NUMB_BACKUPS_TO_KEEP=30
    BACKUP_PATH=/config/backups-files
    BACKUP_NAME=$(date +"%s").bookstack.files.backup.tar.gz
    # -----------------------------------------------

    mkdir -p $BACKUP_PATH

    cd $BACKUP_PATH
    ls -tr | head -n -$NUMB_BACKUPS_TO_KEEP | xargs --no-run-if-empty rm

    cd /config/www
    tar -czvf $BACKUP_PATH/$BACKUP_NAME .env uploads files images
    ```

  * **automatic periodic execution of the backup scripts**

    Using cron running on the host machine that will execute scripts inside containers.

    script `cron_job_do_backups.sh` inside `~/docker/bookstack`

    `cron_job_do_backups.sh`
    ```
    #!/bin/bash

    docker exec bookstack /config/make_backup.sh
    docker exec bookstack_db /config/make_backup.sh
    ```

    `chmod +x cron_job_do_backups.sh` on the host machine

    `crontab -e`

    `0 2 * * * /home/bastard/docker/bookstack/cron_job_do_backups.sh`

### restore official way
  
  * restore of the database

    copy the backup sql dump file in to the bind mount `bookstack-data-db` directory

    exec in to the container and tell mariadb to restore data from the copied file

    `docker exec -it bookstack_db /bin/bash`</br>
    `cd /config`</br>
    `mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < 1584566634.bookstack.database.backup.sql`

  * restore of the files

    copy the backup gz.tar archive in to bind mount `bookstack-data/www/` directory</br>

    `docker exec -it bookstack /bin/bash`</br>
    `cd /config/www`</br>
    `tar -xvzf 1584566633.bookstack.files.backup.tar.gz`
