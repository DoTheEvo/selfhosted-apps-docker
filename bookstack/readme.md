# Bookstack in docker

###### guide by example

![logo](https://i.imgur.com/qDXwqaU.png)

### Purpose

Documentation and notes.

* [Official site](https://www.bookstackapp.com/)
* [Github](https://github.com/BookStackApp/BookStack)
* [DockerHub](https://hub.docker.com/r/linuxserver/bookstack)

### Files and directory structure

  ```
  /home
  └── ~
      └── docker
          └── bookstack
              ├── 🗁 bookstack-data
              ├── 🗁 bookstack-data-db
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

    bookstack_db:
      image: linuxserver/mariadb
      container_name: bookstack_db
      hostname: bookstack_db
      environment:
        - TZ
        - PUID
        - PGID
        - MYSQL_ROOT_PASSWORD
        - MYSQL_DATABASE
        - MYSQL_USER
        - MYSQL_PASSWORD
      volumes:
        - ./bookstack-data-db:/config
      restart: unless-stopped

    bookstack:
      image: linuxserver/bookstack
      container_name: bookstack
      hostname: bookstack
      environment:
        - TZ
        - PUID
        - PGID
        - DB_HOST
        - DB_USER
        - DB_PASS
        - DB_DATABASE
        - APP_URL
        - MAIL_DRIVER
        - MAIL_HOST
        - MAIL_PORT
        - MAIL_FROM
        - MAIL_USERNAME
        - MAIL_PASSWORD
        - MAIL_ENCRYPTION
      volumes:
        - ./bookstack-data:/config
      restart: unless-stopped
      depends_on:
        - bookstack_db

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

  # BOOKSTACK-MARIADB
  PUID=1000
  PGID=1000
  MYSQL_ROOT_PASSWORD=bookstack
  MYSQL_DATABASE=bookstack
  MYSQL_USER=bookstack
  MYSQL_PASSWORD=bookstack

  # BOOKSTACK
  PUID=1000
  PGID=1000
  DB_HOST=bookstack_db
  DB_USER=bookstack
  DB_PASS=bookstack
  DB_DATABASE=bookstack

  # USING SENDGRID FOR SENDING EMAILS
  APP_URL=https://book.blabla.org
  MAIL_DRIVER=smtp
  MAIL_HOST=smtp.sendgrid.net
  MAIL_PORT=465
  MAIL_FROM=book@blabla.org
  MAIL_USERNAME=apikey
  MAIL_PASSWORD=SG.2FA24asaddasdasdasdsadasdasdassadDEMBzuh9e43
  MAIL_ENCRYPTION=SSL
  ```

### Reverse proxy

  Caddy v2 is used,
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

![logo](https://i.imgur.com/cN1GUZw.png)

### Update

  * [watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower) updates the image automaticly

  * manual image update</br>
    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`

### Backup and restore

  * **backup** using [borgbackup setup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
  that makes daily snapshot of the entire directory
    
  * **restore**</br>
    down the bookstack containers `docker-compose down`</br>
    delete the entire bookstack directory</br>
    from the backup copy back the bookstack directortory</br>
    start the container `docker-compose up -d`

### Backup of just user data

user-data daily export using the [official procedure.](https://www.bookstackapp.com/docs/admin/backup-restore/)</br>
For bookstack it means database dump and backing up several directories containing user uploaded files.
The created backup files are overwriten on every run of the script,
but borg backup is daily making snapshot of the entire directory.

* **create a backup script**</br>
    placed inside `bookstack` directory on the host

    `bookstack-backup-script.sh`
    ```
    #!/bin/bash

    # CREATE DATABASE DUMP, bash -c '...' IS USED OTHERWISE OUTPUT > WOULD TRY TO GO TO THE HOST
    docker container exec bookstack_db bash -c 'mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > $MYSQL_DIR/BACKUP.bookstack.database.sql'

    # ARCHIVE UPLOADED FILES
    docker container exec bookstack tar -czPf /config/BACKUP.bookstack.uploaded-files.tar.gz /config/www/
    ```

    the script must be **executabe** - `chmod +x bookstack-backup-script.sh`

* **cronjob** on the host</br>
  `crontab -e` - add new cron job</br>
  `0 2 * * * /home/bastard/docker/bookstack/bookstack-backup-script.sh` - run it [at 02:00](https://crontab.guru/#0_2_*_*_*)</br>
  `crontab -l` - list cronjobs

### Restore the user data

  Assuming clean start, first restore the database before running the app container.

  * start only the database container: `docker-compose up -d bookstack_db`
  * have `BACKUP.bookstack.database.sql` mounted in by placing it in `bookstack/bookstack-data`
  * exec in to the container and restore the database</br>
    `docker container exec -it bookstack_db /bin/bash`</br>
    `cd /config`</br>
    `mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < BACKUP.bookstack.database.sql`
  * now start the app container: `docker-compose up -d`
  * let it run so it creates its file structure
  * down the containers `docker-compose down`
  * in `bookstack/bookstack-data/www/` replace directories `files`,`images` and `uploads` and the file `.env`
    with the ones from the archive `BACKUP.bookstack.uploaded-files.tar.gz` 
  * start the containers: `docker-compose up -d`
  * if there was a major version jump, exec in to the app container and run `php artisan migrate`</br>
    `docker container exec -it bookstack /bin/bash`</br>
    `cd /var/www/html/`</br>
    `php artisan migrate`
