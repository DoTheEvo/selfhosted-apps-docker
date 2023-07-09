# wg-easy

###### guide-by-example

![logo](https://i.imgur.com/IRgkp2o.png)

# Purpose & Overview

Web GUI for Wireguard VPN.<br>

* [Github](https://github.com/WeeJeWel/wg-easy)

Wireguard is the best VPN solution right now. But its not noob friendly or easy.<br>
WG-easy tries to solve this.

Written in javascript.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── wg-easy/
            ├── 🗁 wireguard_data/
            ├── 🗋 .env
            └── 🗋 docker-compose.yml
```              
* `wireguard_data/` - a directory with wireguard config files
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the container

# Compose

`docker-compose.yml`
```yml
services:

  wg-easy:
    image: weejewel/wg-easy:7
    container_name: wg-easy
    hostname: wg-easy
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./wireguard_data:/etc/wireguard
    ports:
      - "51820:51820/udp"  # vpn traffic
      - "51821:51821"      # web interface
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true
```

`.env`
```bash
# GENERAL
DOCKER_MY_NETWORK=caddy_net
TZ=Europe/Bratislava

#WG-EASY
WG_HOST=vpn.example.com
PASSWORD=supersecretpassword
WG_PORT=51820
WG_DEFAULT_ADDRESS=10.221.221.x
WG_ALLOWED_IPS=192.168.1.0/24
WG_DEFAULT_DNS=
```

DNS is set to null, otherwise issues.

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```php
vpn.{$MY_DOMAIN} {
    reverse_proxy wg-easy:51821
}
```

# First run

![loginpic](https://i.imgur.com/V30cDwq.png)

Login with the password from the .env file.<br>
Add user, download config, use it.

# Trouble shooting

# Update

Manual image update:

- `docker compose pull`</br>
- `docker compose up -d`</br>
- `docker image prune`

