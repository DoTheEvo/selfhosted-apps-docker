# Bitwarden_rs in docker

###### guide by example

![logo](https://i.imgur.com/tT3FQLJ.png)

## Purpose

Password manager. RS version is simpler and lighter than the official bitwarden.

* [Official site](https://bitwarden.com/)
* [Github](https://github.com/dani-garcia/bitwarden_rs)
* [DockerHub](https://hub.docker.com/r/bitwardenrs/server)

## Files and directory structure

  ```
  /home
  └── ~
      └── docker
          └── bitwarden
              ├── 🗁 bitwarden-data
              ├── 🗋 .env
              ├── 🗋 docker-compose.yml
              └── 🗋 bitwarden-backup-script.sh
  ```

## docker-compose
  
  [Documentation](https://github.com/dani-garcia/bitwarden_rs/wiki/Using-Docker-Compose) on compose.

  `docker-compose.yml`

  ```
  version: "3"
  services:

    bitwarden:
      image: bitwardenrs/server
      hostname: bitwarden
      container_name: bitwarden
      restart: unless-stopped
      env_file: .env
      volumes:
        - ./bitwarden-data/:/data/

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

  # BITWARDEN
  ADMIN_TOKEN=YdLo1TM4MYEQ948GOVZ29IF4fABSrZMpk9
  SIGNUPS_ALLOWED=true

  # USING SENDGRID FOR SENDING EMAILS
  DOMAIN=https://passwd.blabla.org
  SMTP_SSL=true
  SMTP_EXPLICIT_TLS=true
  SMTP_HOST=smtp.sendgrid.net
  SMTP_PORT=465
  SMTP_USERNAME=apikey
  SMTP_PASSWORD=SG.MOQQegA3bgfodRN4IG2Wqwe.s23Ld4odqhOQQegf4466A4
  SMTP_FROM=admin@blabla.org
  ```

  **All containers must be on the same network**.</br>
  If one does not exist yet: `docker network create caddy_net`

## Reverse proxy

  Caddy v2 is used, details [here.](https://github.com/DoTheEvo/Caddy-v2-docker-example-setup)</br>
  Bitwarden_rs documentation has a [section on reverse proxy.](https://github.com/dani-garcia/bitwarden_rs/wiki/Proxy-examples)
  
  `Caddyfile`
  ```
  {
      # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
  }

  passwd.{$MY_DOMAIN} {
      header / {
         X-XSS-Protection "1; mode=block"
         X-Frame-Options "DENY"
         X-Robots-Tag "none"
         -Server
      }
      encode gzip
      reverse_proxy /notifications/hub/negotiate bitwarden:80
      reverse_proxy /notifications/hub bitwarden:3012
      reverse_proxy bitwarden:80
  }
  ```

## Forward port 3012 on your router

  - websocket protocol used for some kind of notifications

## Extra info

  * **bitwarden can be managed** at `<url>/admin` and entering `ADMIN_TOKEN` set in the `.env` file

---

![interface-pic](https://i.imgur.com/5LxEUsA.png)

## Update

  * [watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower) updates the image automaticly

  * manual image update</br>
    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`

## Backup and restore

  * **backup** using [borgbackup setup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
  that makes daily snapshot of the entire directory
    
  * **restore**</br>
    down the bitwarden container `docker-compose down`</br>
    delete the entire bitwarden directory</br>
    from the backup copy back the bitwarden directortory</br>
    start the container `docker-compose up -d`

## Backup of just user data

user-data daily export using the [official procedure.](https://github.com/dani-garcia/bitwarden_rs/wiki/Backing-up-your-vault)</br>
For bitwarden_rs it means sqlite database dump and backing up `attachments` directory.
The created backup files are overwriten on every run of the script,
but borg backup is daily making snapshot of the entire directory.

* **create a backup script**</br>
    placed inside `bitwarden` directory on the host
    
    `bitwarden-backup-script.sh`
    ```
    #!/bin/bash

    # CREATE SQLITE BACKUP
    docker container exec bitwarden sqlite3 /data/db.sqlite3 ".backup '/data/BACKUP.bitwarden.db.sqlite3'"

    # BACKUP ATTACHMENTS
    docker container exec bitwarden tar -czPf /data/BACKUP.attachments.tar.gz /data/attachments
    ```

    the script must be **executabe** - `chmod +x bitwarden-backup-script.sh`

* **cronjob** on the host</br>
  `crontab -e` - add new cron job</br>
  `0 2 * * * /home/bastard/docker/bitwarden/bitwarden-backup-script.sh` - run it [at 02:00](https://crontab.guru/#0_2_*_*_*)</br>
  `crontab -l` - list cronjobs

## Restore the user data

  Assuming clean start.

  * start the bitwarden container: `docker-compose up -d`
  * let it run so it creates its file structure
  * down the container `docker-compose down`
  * in `bitwarden/bitwarden-data/`</br>
    replace `db.sqlite3` with the backup one `BACKUP.bitwarden.db.sqlite3`</br>
    replace `attachments` directory with the one from the archive `BACKUP.attachments.tar.gz` 
  * start the container `docker-compose up -d`

