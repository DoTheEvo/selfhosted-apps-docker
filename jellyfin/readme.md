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
            └── compose.yml
```

* `/mnt/bigdisk/...` - a mounted media storage share
* `jellyfin_cache/` - cache, includes transcodes
* `jellyfin_config/` - configuration 
* `.env` - a file containing environment variables for docker compose
* `compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the two files.</br>
The directories are created by docker compose on the first run.

# compose

A relatively simple compose.

The only atypical thing is the **passthrough** of the graphic card
for hardware accelerated transcoding.<br>
In the `devices` section a passthrough of a graphic card is done,
`/dev/dri/renderD128` refering to the first gpu of the system<br> 
In `group_add` section permissions are set.
You want to execute the command: `getent group render | cut -d: -f3`
to get the correct group number for you system and set it in.

This all can be left as is even if no gpu is planned to be used.

`compose.yml`
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
      - /mnt/bigdisk/tv:/media/tv:ro
      - /mnt/bigdisk/movies:/media/movies:ro
      - /mnt/bigdisk/music:/media/music:ro
    ports:
      - "8096:8096"       # webGUI
      - "1900:1900/udp"   # autodiscovery on local networks

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
tv.{$MY_DOMAIN} {
    reverse_proxy jellyfin:8096
}
```

# The first run


<!-- ![interface-pic](https://i.imgur.com/pZMi6bb.png) -->

Click through basic setup.

WORK IN PROGRESS

WORK IN PROGRESS

WORK IN PROGRESS

# Transcoding

### The basics

* a **video file** is just a bunch of pictures - **frames**,
  somehow packed in to one file.
* To save up disk space and bandwidth its **compressed** using some video
  standard/codec.
  * MPEG-2 - stuff of the past
  * **H.264** - the most common now
  * **H.265** - also called **HEVC**, fast spreading, 50% improved over H.264
  * **AV1** - the future, open codec - no licencing fees, more improvements
* Ways to transcode
  * **Software** - cpu does the job, uses some library, it is **very cpu heavy**<br>
    a phone doing a software playback would either stutter, or be through
    the entire battery in 30 minutes.
  * **Hardware** - there is a dedicated hardware - a tiny part of a cpu/gpu/soc
    that is designed for just one thing - to transcode a specific video standard.
    That means it is **extremely efficient** at it.
* Terminology
  * **Decode** - taking a compressed video file and turning it into a viewable format.
  * **Encode** - compressing raw video in to a specific video format
  * **Transcode** - converting a video format in to a different format,
    consists of both decode and encode steps


Ideally you deploy jellyfin somewhere with an igpu to get hardware accelerated
transcoding, but it is far from required.
For most people, majority of media will be in H.264 or H.265 which will be
**direct play** - no transcoding required on most devices.<br>
Even if theres occasional need to transcode, average cpu can do one or two streams.

If you plan to serve more people and have larger library you should
definitly plan to have something with igpu

#### HDR

The issue starts with 4k content, of which majority also uses
HDR - High Dynamic Range. This is for benefit of HDR TVs, monitors, phones,...
To play on non-HDR devices transcoding is always required and not just typical
transcoding, but also tonemapping as trancoding HDR content without it will make colors seem
heavily desaturated - washed out.

* Not all devices like phones, PCs - browsers, TVs, streaming boxes,...
  have build in support for all these standard.
* If video is in H.265 but firefox on linux cant decode it,
  jellyfin detects this and transcodes it to something that can be played.







The above compose basic setup worked for me

* ryzen 1700, headless, without any gpu
* modern intel cpus with igpu - n200, i5-125600k
* modern amd ryzens with igpu - 7700x, 5500GT

but how to setup things might change over time so one should check
[the official documentation](https://jellyfin.org/docs/general/administration/hardware-acceleration/intel#configure-with-linux-virtualization)



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
  What=//10.0.19.11/Dataset-01
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

- `docker compose pull`</br>
- `docker compose up -d`</br>
- `docker image prune`

# Useful

* https://www.reddit.com/r/selfhosted/comments/1bit5xr/livetv_on_jellyfin_2024/
