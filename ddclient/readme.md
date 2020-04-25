# DDclient in docker

###### guide by example

# Purpose

Automatic DNS entries update. Useful if no static IP from ISP.

* [Official site](https://sourceforge.net/p/ddclient/wiki/usage/)
* [Github](https://github.com/ddclient/ddclient)
* [DockerHub](https://hub.docker.com/r/linuxserver/ddclient)

# Files and directory structure

```
/home
└── ~
    └── docker
        └── ddclient
            ├── 🗋 .env
            ├── 🗋 docker-compose.yml
            └── 🗋 ddclient.conf
```              

# docker-compose
  
[Based on linuxserver.io](https://hub.docker.com/r/linuxserver/ddclient)

`docker-compose.yml`

```yml
version: "2.1"
services:

  ddclient:
    image: linuxserver/ddclient
    hostname: ddclient
    container_name: ddclient
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./ddclient.conf:/config/ddclient.conf
    restart: unless-stopped
```

`.env`

```bash
# GENERAL
MY_DOMAIN=blabla.org
DEFAULT_NETWORK=caddy_net
TZ=Europe/Prague

#LINUXSERVER.IO
PUID=1000
PGID=1000
```

# Configuration

Official ddclient config example
[here](https://github.com/ddclient/ddclient/blob/master/sample-etc_ddclient.conf).</br>
Make sure A-records exist on cloudflare.

`ddclient.conf`

```bash
daemon=600
syslog=yes
mail=root
mail-failure=root
pid=/var/run/ddclient/ddclient.pid
ssl=yes

use=web, web=checkip.dyndns.org/, web-skip='IP Address'
wildcard=yes

##
## CloudFlare (www.cloudflare.com)
##
protocol=cloudflare,        \
zone=blabla.org,              \
ttl=1,                      \
login=bastard.blabla@gmail.com, \
password=global-api-key-goes-here \
blabla.org,*.blabla.org,subdomain.blabla.org

protocol=cloudflare,        \
zone=blabla.tech,              \
ttl=1,                      \
login=bastard.blabla@gmail.com, \
password=global-api-key-goes-here \
blabla.net,*.blabla.net,whatever.blabla.org
```

# Update

  * [watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower)
   updates the image automaticly

  * manual image update</br>
    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`
