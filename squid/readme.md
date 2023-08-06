# Squid

###### guide-by-example

![logo](https://i.imgur.com/U42Ot3z.jpg)

# Purpose & Overview

Forward proxy to avoid websites IP bans.<br>

* [Official](http://www.squid-cache.org/)
* [Github](https://github.com/squid-cache/squid)

Caching and forwarding HTTP web proxy.<br>
Main use here is being able to access web pages from a different IP than 
your own in a comfortable way.

Squid is written in C++.

# Hosting

Free oracle cloud instance can be used.<br>
[Detailed setup guide here.](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/free_cloud_hosting_VPS)

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── squid/
            ├── 🗋 docker-compose.yml
            └── 🗋 squid.conf
```              
* `docker-compose.yml` - a docker compose file, telling docker how to run the container
* `squid.conf` - main configuration files for squid

# Compose

`docker-compose.yml`
```yml
services:
  squid:
    image: ubuntu/squid
    container_name: squid
    hostname: squid
    restart: unless-stopped
    ports:
      - "56566:56566"
    volumes:
      - ./squid.conf:/etc/squid/squid.conf
      - ./squid_cache:/var/spool/squid    
```

# squid.conf

Minimal config that works.<br>

For running in docker `max_filedescriptors 1048576` is required, prevents error:<br>
*FATAL: xcalloc: Unable to allocate 1073741816 blocks of 432 bytes
squid cache terminated abnormally*

`squid.conf`
```php
max_filedescriptors 1048576
http_port 56566
http_access allow all
```

Linux curl command can test if reverse proxy works.

`curl -x http://666.6.66.6:56566 -L http://archlinux.org`

# More configuration

For security I use firewall that allows in connections only from one public IP.
Or I would be using VPN. So not much interest in security acl and authorization config.

Also no interest in caching.
So this is just some config with some headers turned off for maybe better hiding
of the real IP.

`squid.conf`
```php
max_filedescriptors 1048576
http_port 56566
http_access allow all

cache deny all
visible_hostname squidproxy

forwarded_for delete
via off
follow_x_forwarded_for deny all
request_header_access X-Forwarded-For deny all
```

* [arch wiki](https://wiki.archlinux.org/title/Squid)
* 

# Usage

FoxyProxy Standard - got version on firefox and chrome.

In config one can setup ip and port and it works.<br>
But it also has pattern section where url wildcard can be set and proxy is applied
only on those sites.

# Update

Manual image update:

- `docker compose pull`</br>
- `docker compose up -d`</br>
- `docker image prune`

