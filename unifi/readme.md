# UniFi Network Application

###### guide-by-example

![logo](https://i.imgur.com/tAEVBnp.png)

# Purpose & Overview

Ubiquiti managment software for **wifi** access points and other ubiquiti hardware.<br>

* [Official site](https://www.ui.com/software/)
* [linuxserver github](https://github.com/linuxserver/docker-unifi-network-application)

UniFi is a web based managment software for Ubiquiti devices.</br>
It is written in Java, utilizing the Spring Framework
and using MongoDB as a database.<br>
Docker image used here is provided by
[linuxserver.io](https://www.linuxserver.io/)

# Migration from UniFi Controller

* Do the manual **backup** of your old instance, through webgui settings.
* Down the old container.
* Spin the new stuff
* Restore the backup

<details>
<summary>Extra Info & Rant</summary>
<br>

Previously called [UniFi Controller](https://github.com/linuxserver/docker-unifi-controller)

Ubiquiti morons decided to change the name to UniFi Network Application.
Then also tried to go for name UniFi Network Server with a claim that its for 
selfhosted version. In docs and even in downloads they mostly use the `application`.<br>
Though love that inside the webgui version its just `Network 8.0.28`

With this name change, linuxserver.io also changed the deployment so that
mongo database is now a separate container.<br>
Would not be a big issue, if mongo would not [suck big time](https://github.com/docker-library/mongo/issues/174)
at initiating databases in new deployments, making it unnecessary complicated.
Or if linuxserver.io could make a decision and write
[cleaner instructions](https://github.com/linuxserver/docker-unifi-network-application/issues/13)
instead of trying to teach to fish.<br>
Also linuxserver.io official stance is to use older version of mongo v3.6 - v4.4<br>
Reports are that raspberry pi 4 users need to go for that v3.6

Big help to get this going cleanly was [this repo](https://github.com/GiuseppeGalilei/Ubiquiti-Tips-and-Tricks),
from [this](https://www.reddit.com/r/Ubiquiti/comments/18stenb/unifi_network_application_easy_docker_deployment/)
reddit post.<br>
First time Ive seen `configs` used in compose this way, saved a bother of doing
a separate mounting of `mongo-init.js`, that for some reason did not work for me.
Here it is improved a bit by using variables, so stuff can be set just in `.env`

</details>

![backup_restore](https://i.imgur.com/WYleMWj.png)

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── unifi/
            ├── 🗁 mongo_db_data/
            ├── 🗁 unifi_data/
            ├── 🗋 .env
            └── 🗋 docker-compose.yml
```

* `mongo_db_data/` - database data 
* `unifi_data/` - unifi configuration and other data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker
  how to run the containers

You only need to provide the files.</br>
The directory is created by docker compose on the first run.

# docker-compose

Compose should not need any changes, theres `.env` file for that.

Worth noting is use of [configs](https://docs.docker.com/compose/compose-file/08-configs/)
to bypass the need for separate `mongo-init.js` file.<br>
The use comes from [this repo](https://github.com/GiuseppeGalilei/Ubiquiti-Tips-and-Tricks).

`docker-compose.yml`
```yml
services:

  unifi-db:
    image: mongo:4
    container_name: unifi-db
    hostname: unifi-db
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./mongo_db_data:/data
    expose:
      - 27017
    configs:
      - source: init-mongo.js
        target: /docker-entrypoint-initdb.d/init-mongo.js

  unifi-app:
    image: lscr.io/linuxserver/unifi-network-application:8.1.127
    container_name: unifi-app
    hostname: unifi-app
    restart: unless-stopped
    env_file: .env
    depends_on:
      - unifi-db
    volumes:
      - ./unifi_data:/config
    ports:
      - 8443:8443
      - 3478:3478/udp
      - 10001:10001/udp
      - 8080:8080
      - 1900:1900/udp #optional
      - 8843:8843 #optional
      - 8880:8880 #optional
      - 6789:6789 #optional
      - 5514:5514/udp #optional

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true

configs:
  init-mongo.js:
    content: |
      db.getSiblingDB("$MONGO_DBNAME").createUser({user: "$MONGO_USER", pwd: "$MONGO_PASS", roles: [{role: "readWrite", db: "$MONGO_DBNAME"}]});
      db.getSiblingDB("${MONGO_DBNAME}_stat").createUser({user: "$MONGO_USER", pwd: "$MONGO_PASS", roles: [{role: "readWrite", db: "${MONGO_DBNAME}_stat"}]});
```

`.env`
```bash
# GENERAL
DOCKER_MY_NETWORK=caddy_net
TZ=Europe/Bratislava

#UNIFI LINUXSERVER.IO
PUID=1000
PGID=1000
MEM_LIMIT=1024
MEM_STARTUP=1024
MONGO_USER=unifi
MONGO_PASS=N9uHz2bt
MONGO_HOST=unifi-db
MONGO_PORT=27017
MONGO_DBNAME=unifi_db
# MONGO_TLS= #optional
# MONGO_AUTHSOURCE= #optional
```

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
unifi.{$MY_DOMAIN} {
        encode gzip
        reverse_proxy unifi-app:8443 {
                transport http {
                        tls
                        tls_insecure_skip_verify
                }
        }
}
```

# Adoption

![override_pic](https://i.imgur.com/VyCqaCp.png)

The controller might see your APs during initial setup,
but it can not adopt them before you set your docker host IP
as `Override Inform Host`.

* **Inform Host** check the **Override** checbox<br>
  *Settings > System > Advanced*<br>
* enter docker-host IP
* adopt devices

# Some Settings

* **Disable "Connects high performance clients to 5 GHz only"**<br>
  *Old interface > Settings > Wireless Networks > Edit > Advanced Options*<br>
  When enabled it forces devices to ignore 2.4GHz which obviously causes problems at range. 
  Fucking monstrous stupidity to be default on,
  but I guess globaly they have power to cleanup 2.4GHz a bit.
* **802.11 DTIM Period - sets to 3**<br>
  *Settings > Wifi > Edit > Advanced*<br>
  For [apple devices](https://www.sniffwifi.com/2016/05/go-to-sleep-go-to-sleep-go-to-sleep.html)<br>

# Update

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

