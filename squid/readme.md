# Squid

###### guide-by-example

![logo](https://i.imgur.com/U42Ot3z.jpg)

# Purpose & Overview

Forward proxy to avoid websites IP bans.<br>

* [Official](http://www.squid-cache.org/)
* [Github](https://github.com/squid-cache/squid)
* [Arch wiki](https://wiki.archlinux.org/title/Squid)

Caching and forwarding HTTP web proxy.<br>
Main use here is being able to access web pages from a different IP than 
your own in a comfortable way.<br>
Other uses are caching to improve speed and load, and ability to block domains,
ads, IPs,...

Squid is written in C++.

# Hosting

Free oracle cloud instance can be used to host squid somewhere in the world.<br>
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

A minimal config that works.

For running in docker, `max_filedescriptors 1048576` is required, prevents error:<br>
*FATAL: xcalloc: Unable to allocate 1073741816 blocks of 432 bytes
squid cache terminated abnormally*

A firewall is used for security, allows in-connections only from one public IP.
Otherwise a VPN like wireguard would be used,
so not much interest in acl security and authorization provided by the config.<br>
Also no interest in caching.<br>
So this is just a config with some headers turned off for maybe better hiding
of the real IP.

**Testing**

Linux curl command can test if reverse proxy works.

`curl -x http://666.6.66.6:56566 -L http://archlinux.org`

# Setting proxy in browsers

![foxy](https://i.imgur.com/oYIA5u1.jpg)

Every browser has proxy settings where ip and port can be set and it should 
work globally for every site. But if only certain domains should go through proxy
then thers browsers addons.

**FoxyProxy Standard**

* [firefox](https://addons.mozilla.org/en-US/firefox/addon/foxyproxy-standard/)
* [chrome](https://chrome.google.com/webstore/detail/foxyproxy-standard/gcknhkkoolaabfmlnjonogaaifnjlfnp)

In config one can setup the proxy ip and port and then one can enable or disable proxy.<br>
But it also has pattern section where url wildcard can be set and proxy
is enabled all the time but applies only on sites fitting pattern.

# Update

Manual image update:

- `docker compose pull`</br>
- `docker compose up -d`</br>
- `docker image prune`

