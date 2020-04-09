# Bitwarden_rs in docker

###### guide by example

![logo](https://i.imgur.com/BQ9Ec6f.png)

### Purpose

Password manager. RS version is simpler and lighter than the official bitwarden.

* [Official site](https://bitwarden.com/)
* [Github](https://github.com/dani-garcia/bitwarden_rs)
* [DockerHub image used](https://hub.docker.com/r/bitwardenrs/server)

### Files and directory structure

  ```
  /home
  └── ~
      └── docker
          └── bitwarden
              ├── 🗁 bitwarden-backup
              ├── 🗁 bitwarden-data
              ├── 🗋 .env
              ├── 🗋 docker-compose.yml
              └── 🗋 bitwarden-backup-script.sh
  ```

### docker-compose
  
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
      volumes:
        - ./bitwarden-data/:/data/
      environment:
        - TZ
        - ADMIN_TOKEN
        - DOMAIN
        - SIGNUPS_ALLOWED
        - SMTP_SSL
        - SMTP_EXPLICIT_TLS
        - SMTP_HOST
        - SMTP_PORT
        - SMTP_USERNAME
        - SMTP_PASSWORD
        - SMTP_FROM

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
  DOMAIN=https://passwd.blabla.org
  SIGNUPS_ALLOWED=true

  # USING SENDGRID FOR SENDING EMAILS
  SMTP_SSL=true
  SMTP_EXPLICIT_TLS=true
  SMTP_HOST=smtp.sendgrid.net
  SMTP_PORT=465
  SMTP_USERNAME=apikey
  SMTP_PASSWORD=SG.MOQQegA3bgfodRN4IG2Wqwe.s23Ld4odqhOQQegf4466A4
  SMTP_FROM=admin@blabla.org
  ```

### Reverse proxy

  Caddy v2 is used, details [here.](https://github.com/DoTheEvo/Caddy-v2-examples)</br>
  Bitwarden_rs documentation has a [section on reverse proxy.](https://github.com/dani-garcia/bitwarden_rs/wiki/Proxy-examples)
  
  `Caddyfile`
  ```
  {
      # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
  }

  passwd.{$MY_DOMAIN} {
      encode gzip
      reverse_proxy /notifications/hub/negotiate bitwarden:80
      reverse_proxy /notifications/hub bitwarden:3012
      reverse_proxy bitwarden:80
  }
  ```

### Forward port 3012 on your router

  - websocket protocol used for some kind of notifications

### Extra info

  * **bitwarden can be managed** at `passwd.blabla.org/admin` and entering `ADMIN_TOKEN` set in the `.env` file

![interface-pic](https://i.imgur.com/5LxEUsA.png)

### Update

  * [watchtower](https://github.com/DoTheEvo/docker-selfhosted-projects/tree/master/watchtower) updates the image automaticly

  * manual image update</br>
    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`

### Backup and restore

  * **backup** using [borgbackup setup](https://github.com/DoTheEvo/docker-selfhosted-projects/tree/master/borg_backup)
  that makes daily backup of the entire directory
    
  * **restore**</br>
    down the bitwarden container `docker-compose down`</br>
    delete the entire bitwarden directory</br>
    from the backup copy back the bitwarden directortory</br>
    start the container `docker-compose up -d`

### Backup of just user data

For additional peace of mind.
Having user-data daily exported using the [official procedure.](https://github.com/dani-garcia/bitwarden_rs/wiki/Backing-up-your-vault)</br>
For bitwarden_rs it means sqlite database dump and the content of the `attachments` folder.
The backup files are overwriten on every run of the script,
but borg backup is backing the entire directory in to snapshots daily, so no need for some keeping-last-X consideration.

* **install sqlite on the host system**

* **create backup script**</br>
    placed inside `bitwarden` directory on the host
    
    `make_bitwarden_backup.sh`
    ```
    #!/bin/sh

    # GO IN TO THE DIRECTORY WHERE THIS SCRIPT RESIDES
    cd "${0%/*}"

    # CREATE BACKUP DIRECTORY IF IT DOES NOT EXIST
    mkdir -p ./bitwarden-backup

    # CREATE SQLITE BACKUP
    sqlite3 ./bitwarden-data/db.sqlite3 ".backup './bitwarden-BACKUP.db.sqlite3'"

    # BACKUP ATTACHMENTS
    tar -czvf ./bitwarden-backup/attachments.tar.gz ./bitwarden-data/attachments
    ```

    the script must be executabe - `chmod +x make_bitwarden_backup.sh`

* **cronjob** on the host</br>
  `crontab -e` - add new cron job</br>
  `0 2 * * * /home/bastard/docker/bitwarden/bitwarden-backup-script.sh` - run it [at 02:00](https://crontab.guru/#0_2_*_*_*)</br>
  `crontab -l` - list cronjobs

### Restore the user data

  - down the container `docker-compose down`</br> 
  - replace `db.sqlite3` with the one from the backup
  - replace attachments folder with the one from the backup
  - start the container `docker-compose up -d`

