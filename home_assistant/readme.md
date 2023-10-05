# Home Assistant

###### guide-by-example

![logo](https://i.imgur.com/lV7LdOC.png)

# Purpose & Overview

WORK IN PROGRESS<br>
WORK IN PROGRESS<br>
WORK IN PROGRESS<br>

Home monitoring and automation system or some shit for cameras with frigate nvr.

* [Official site](https://www.home-assistant.io/)
* [Github](https://github.com/home-assistant)

Dunno

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── home_assistant/
            ├── home_assistant_config/
            ├── .env
            └── docker-compose.yml
```

* `home_assistant_config/` - configuration 
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the two files.</br>
The directories are created by docker compose on the first run.

# docker-compose

`docker-compose.yml`
```yml
services:

  homeassistant:
    image: "ghcr.io/home-assistant/home-assistant:stable"
    container_name: homeassistant
    hostname: homeassistant
    privileged: true
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./home_assistant_config:/config
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "8123:8123"

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
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

# Reverse proxy

Caddy is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```bash
home.{$MY_DOMAIN} {
    reverse_proxy homeassistant:8123
}
```

For security the following needs to be added to home assistant config file,
which gets created on the first run in the direcotry `home_assistant_config`

`configuration.yaml`

```yml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.16.0.0/12
  ip_ban_enabled: true
  login_attempts_threshold: 10
```


----------  end for now -----------

# First run


![interface-pic](https://i.imgur.com/pZMi6bb.png)


# Specifics of my setup

* no long term use yet
* amd cpu and no gpu, so no experience with hw transcoding
* media files are stored and shared on trunas scale VM
 and mounted directly on the docker host using [systemd mounts](https://forum.manjaro.org/t/root-tip-systemd-mount-unit-samples/1191),
 instead of fstab or autofs.

  `/etc/systemd/system/mnt-bigdisk.mount`
  ```ini
  [Unit]
  Description=12TB truenas mount

  [Mount]
  What=//10.0.19.19/Dataset-01
  Where=/mnt/bigdisk
  Type=cifs
  Options=ro,username=ja,password=qq,file_mode=0700,dir_mode=0700,uid=1000
  DirectoryMode=0700

  [Install]
  WantedBy=multi-user.target
  ```

  `/etc/systemd/system/mnt-bigdisk.automount`
  ```ini
  [Unit]
  Description=12TB truenas mount

  [Automount]
  Where=/mnt/bigdisk

  [Install]
  WantedBy=multi-user.target
  ```

  to automount on boot - `sudo systemctl enable mnt-bigdisk.automount`

# Troubleshooting


![error-pic](https://i.imgur.com/KQhmZTQ.png)

*We're unable to connect to the selected server right now. Please ensure it is running and try again.*

If you encounter this, try opening the url in browsers private window.<br>
If it works then clear the cookies in your browser.


# Update

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

# Backup and restore

#### Backup

Using [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the entire directory.
  
#### Restore

* down the bookstack containers `docker-compose down`</br>
* delete the entire bookstack directory</br>
* from the backup copy back the bookstack directory</br>
* start the containers `docker-compose up -d`
