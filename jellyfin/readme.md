# Jellyfin in docker

###### guide-by-example

![logo](https://i.imgur.com/gSyMEvD.png)

# Purpose & Overview

Stream movies/tv-shows/music to a browser, or a [large selection of devices and services.](https://jellyfin.org/clients/) 

* [Official site](https://jellyfin.org/)
* [Github](https://github.com/jellyfin/jellyfin)
* [DockerHub](https://hub.docker.com/r/jellyfin/jellyfin/)

Jellyfin if a free media system, an alternative to proprietary Plex.<br>
The core server side is written in C#, web client in Javascript,
and a number of other clients written in various languages and frameworks.

Starting point for me was [this viggy96 repo](https://github.com/viggy96/container_config)

# Files and directory structure

```
/mnt/
└── bigdisk/
    ├── tv/
    ├── movies/
    └── music/
/home/
└── ~/
    └── docker/
        └── jellyfin/
            ├── jellyfin_cache/
            ├── jellyfin_config/
            ├── .env
            └── docker-compose.yml
```

* `/mnt/bigdisk/...` - a mounted media storage share
* `jellyfin_cache/` - cache, includes transcodes
* `jellyfin_config/` - configuration 
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the two files.</br>
The directories are created by docker compose on the first run.

# docker-compose

Relatively simple compose.<br>
The only special thing being the passthrough of the graphic card
for hardware accelerated transcoding.
This is done in the `devices` section along with permissions in `group_add`.

This basic setup worked for me with modern intel and amd cpus with igpu,
but how to setup things might change over time so one should check
[the official documentation](https://jellyfin.org/docs/general/administration/hardware-acceleration/intel#configure-with-linux-virtualization)

`docker-compose.yml`
```yml
services:

  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    hostname: jellyfin
    restart: unless-stopped
    env_file: .env
    devices:   
      - /dev/dri/renderD128:/dev/dri/renderD128  # ls /dev/dri
    group_add:
      - "989"  # match output of: getent group render | cut -d: -f3
    volumes:
      - ./jellyfin_config:/config
      - ./jellyfin_cache:/cache
      - /mnt/smb_share/filmy_1:/media/filmy_1:ro
      - /mnt/smb_share/filmy_2:/media/filmy_2:ro
      - /mnt/smb_share/filmy_3:/media/filmy_3:ro
      - /mnt/smb_share/shows:/media/shows:ro
    ports:
      - "8096:8096"
      - "1900:1900/udp"

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

</details>

# Reverse proxy

Caddy is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
jellyfin.{$MY_DOMAIN} {
    reverse_proxy jellyfin:8096
}
```

# First run


![interface-pic](https://i.imgur.com/pZMi6bb.png)


# Specifics of my setup

* no real long term use
* findroid app does not jump subtitles like official one
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

*No playback at all but GUI works fine*

Might be no access to network share, for example if dockerhost boots up faster
than NAS.

# Update

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

# Useful

* https://www.reddit.com/r/selfhosted/comments/1bit5xr/livetv_on_jellyfin_2024/
