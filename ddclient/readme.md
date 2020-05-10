# DDclient in docker

###### guide by example

# Purpose & Overview

Automatic DNS entries update. 

* [Official site](https://sourceforge.net/p/ddclient/wiki/usage/)
* [Github](https://github.com/ddclient/ddclient)
* [DockerHub](https://hub.docker.com/r/linuxserver/ddclient)

DDclient is a Perl client used to update dynamic DNS records.</br>
Useful if not having a static IP from ISP, so that if you reset your router,
or have power outage, and you get a new public IP assigned,
this IP gets automaticly set in the DNS records for your domains.

In this setup it works by checking every 10 minutes
[checkip.dyndns.org](http://checkip.dyndns.org/),
and if the IP changed from the previous one, it updates the DNS records. 

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── ddclient/
            ├── .env
            ├── docker-compose.yml
            └── ddclient.conf
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
TZ=Europe/Bratislava

#LINUXSERVER.IO
PUID=1000
PGID=1000
```

# Configuration

Official ddclient config example
[here](https://github.com/ddclient/ddclient/blob/master/sample-etc_ddclient.conf).

This setup assumes the DNS records are managed Cloudflare.</br>
Make sure all subdomains in the config have A-records.

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

##
protocol=cloudflare,        \
zone=blobloblo.net,              \
ttl=1,                      \
login=bastard.blobloblo@gmail.com, \
password=global-api-key-goes-here \
blobloblo.net,*.blobloblo.net,whatever.blobloblo.org
```

# Update

* [watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower)
 updates the image automaticly

* manual image update</br>
  `docker-compose pull`</br>
  `docker-compose up -d`</br>
  `docker image prune`
