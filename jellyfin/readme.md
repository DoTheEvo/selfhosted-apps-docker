# Jellyfin in docker

###### guide-by-example

![logo](https://i.imgur.com/5JEyoyF.png)

![interfacepic](https://i.imgur.com/KKmcc7g.jpeg)

# Purpose & Overview

Stream movies, shows, music to a phone, a TV, a browser, ...<br>
Something like your own Netflix.

* [The Official site](https://jellyfin.org/)
* [Github](https://github.com/jellyfin/jellyfin)
* [DockerHub](https://hub.docker.com/r/jellyfin/jellyfin/)

Jellyfin is free and opensource without any limitation.

The server can be installed on windows, or on linux or run as a docker container.<br>
It's written in C#, web client in Javascript
and a number of other [clients](https://jellyfin.org/clients/) written in
various languages and frameworks.


<details>
<summary><h1>Video - core concepts</h1></summary>

![encoding-pic](https://i.imgur.com/s2vQxG1.png)

* a **video file** is a bunch of pictures - **frames**,
  packed in to one file.
* To save disk space and bandwidth its **compressed** using a video standard/codec.
  * **H.262** - also called MPEG-2 - stuff of the past.
  * **H.264** - the most common now, also called **AVC** or MPEG-4.
  * **H.265** - also called **HEVC**, fast spreading, 50% improved over H.264,<br>
    but it also greatly increased fees for developers and manufacturers and and came 
    with a convoluted patent pools.
  * **AV1** - the future, no royalty fees, more improvements.
    The successor to VP9, which was developed by google.
* Ways to transcode
  * **Software** - cpu does the job, uses some library, it is **very cpu heavy**<br>
    a phone doing a software playback would either stutter, or be through
    the entire battery in 30 minutes.
  * **Hardware** - there is a dedicated hardware - `ASIC` - a tiny part
    of a cpu/gpu/soc that is designed for just one thing -
    to transcode a specific video standard. It is extremely efficient at it.
* `standard` vs `codec`
  * **Video Compression Standard** - set of specifications to follow, like a recipe,
    examples are H.264, H.265, AV1,..
  * **Codec** - The actual software or hardware implementation of a standard,
    a cook that follows a recipe and gives you a finished meal.
    Examples are `x264`, `x265`, `libaom`, or hardware ASICs on a gpu
    or a cpu like nvidia `NVENC` or `intel quick sync`.
* Other terminology
  * **Bitrate** - how much data per seconds flow, for example 2Mbps or 20Mbps,<br>
    higher bitrate means better quality and larger files/bandwidth needs
  * **Decode** - taking a compressed video file and turning it into a viewable format.
  * **Encode** - compressing raw video in to a specific video format
  * **Transcode** - converting a video format in to a different format,
    consists of both decode and encode steps
  * **Direct Play** - No transcoding required. The device that is trying to play
    the video is able to do so with its hardware.
  * **HDR** - High Dynamic Range. A new technology to improve contrast and visible
    details but lacks wide hardware support yet.
    The opposite is SDR - Standard Dynamic Range.
  * **ffmpeg** - a command line application, open source,
    contains codec libraries to be a single tool for all video manipulation.
    Is often the one under the hood of any media related software, doing the work.

</details>

---
---

<details>
<summary><h1>Jellyfin transcoding</h1></summary>

![jelly-transcoding-pic](https://i.imgur.com/9U1A02j.png)

Jellyfin streams media files to client applications.<br>
In most cases it's **direct play**, no transcoding required and any machine
can do dozens of **concurent streams** in direct play.

But there are cases **when a client does not support codec** of the video file.<br>
Example is Firefox playing a movie encoded in HEVC(x265).<br>
Jellyfin knows which codecs client supports and if needed
it **transcodes video on the fly**, as it's being streamed.<br>
Another reason to transcode can be if you set a hard limit on bandwidth
use per stream.<br>
In `Dashboard` > `Playback` > `Streaming` setting lets say
[2Mbps.](https://i.imgur.com/7hSf4e1.png)

Out of the box, jellyfin is set to **use cpu for software transcoding**.
It will work fine for one or two simple 1080p concurent streams,
unless the cpu is really underpowered/old,
but it will put [a heavy load](https://i.imgur.com/rjNFN1J.png)
on the CPU.

### Hardware acceleration

* [official docs](https://jellyfin.org/docs/general/administration/hardware-acceleration/)

Ideally jellyfin is running on something that can offer hardware accelerated
transcoding, using iGPU which greatly improves performance and power consumption.

* **Intel** - QSV - intel quicksync. Go-To recommendation and ideal for most users,
  high quality, fast, reliable drivers, cheap and low power consumption as an igpu.
  Huge userbase.
* **AMD**  - VAAPI when in docker - kinda shunned as historicly it had the worst
  encode quality. [AMD improved some](https://youtu.be/H0pCpNT4b-Q),
  but so did the competition so it's still not as good. But in real use
  most people would likely not be able to tell difference.<br>
  AV1 encode supported by their newest stuff finally concludes the discussion
  as it's praised for great quality.
* **nvidia** - NVENC - quality not as good as intel, but better than amd,
  driver limit of 8 encoding sessions. Not an ideal solution as a pcie card will
  consume some extra power.
* **Intel Arc** - QSV - relatively new hardware, should be great,
  but be careful about idle power consumption,
  some reviews post \~30W idle for arc while \~5W for amd/nvidia.

But to repeat:<br>
Very likely majority of media will be in h.264 and h.265 and **overwhelming
majority of devices can play these straight up - direct play**. So no need to
overthink transcoding hardware much.<br>
That is unless you want to go 4K + HDR.

### 4K and HDR

![tonemapping](https://i.imgur.com/kAz2HkY.gif)

With 4K resolution often comes **HDR** - High Dynamic Range.<br>
If its played on HDR device all is fine and theres better contrast and details.
But non-HDR devices need transcoding with tonemapping.<br>
**Tonemapping** is what converts HDR content to **SDR** - Standard Dynamic Range.
Without tonemapping the colors would be heavily desaturated - washed out.

Some **clients**, like Findroid on android use mpv for playback, which somehow
deals with the HDR to SDR conversion on its own.
Might be better since its direct play, but might be worse because of putting load
on the device.

### Testing various hardware

Archlinux straight on metal, docker Jellyfin.<br>
Testing [10x FHD streams](https://i.imgur.com/nP71y0E.png),
and 4K+HDR+tonemapping till see stutter <br>
Testing by running movies, x265 encoded, in edge under linux.<br>
`Throttle Transcodes` is turned off so that the movies are transcoded in full,
not just 3min segments. 

Results

* ryzen **7700X**
  * 10x streams FHD - [pass](https://i.imgur.com/NAyfXmG.png)
  * 4K+HDR+tonemapping - not tested
* intel **n200**
  * 10x streams FHD - [pass](https://i.imgur.com/nP71y0E.png)
  * 4K+HDR+tonemapping - not tested
* ryzen **8600G**
  * 10x streams FHD - [pass](https://i.imgur.com/9R60Spw.png)<br>
    except [weird green artifacts](https://i.imgur.com/s4lSJRI.png)
    for ~30sec when starting all 10 streams at once
  * 4K+HDR+tonemapping - not tested
  * AV1 encoding - [worked](https://i.imgur.com/ZaQRIAc.png)
* intel **i5-12600k**
  * 10x streams FHD - [pass](https://i.imgur.com/BGXOeGS.png)
  * 4K+HDR+tonemapping - [4 streams](https://i.imgur.com/yvP72UU.jpeg)
* ryzen **4350GE**
  * 10x streams FHD - 6 max, otherwise stutter
  * 4K+HDR+tonemapping - [1x stream](https://i.imgur.com/8iairvO.png)


Software used for monitoring the cpu and gpu usage

* [btop](https://github.com/aristocratos/btop) 
* `intel_gpu_top` from [intel-gpu-tools](https://archlinux.org/packages/extra/x86_64/intel-gpu-tools/) package
* `radeontop` from [radeontop](https://archlinux.org/packages/extra/x86_64/radeontop/) package

</details>

---
---

# Clients 

Jellyfin's open source nature allows developers to create unofficial client apps.

* [Awesome Jellyfin Clients List](https://github.com/awesome-jellyfin/awesome-jellyfin/blob/main/CLIENTS.md)

The ones I tried and find interesting.

### [Findroid](https://github.com/jarnedemeulemeester/findroid)

Feels bit better in user interface and control.<br>
Does not jump subtitles like the official client,
also seems it's always directplay even 4k+HDR, have to investigate
how the fuck does it do. Uses mpv, but does it mean theres some big load
on a phone when compared to the official app?<br>
It ignores max streaming bandwidth limit when server streams over the internet.

### [Finamp](https://github.com/jmshrv/finamp)

Aimed for music. Did not tested much yet.

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

# Compose

* [the official documentation](https://jellyfin.org/docs/general/installation/container)

A relatively simple compose.

The only atypical thing is the **passthrough** of the graphic card
for hardware accelerated transcoding.
It's in the `devices` section `/dev/dri/renderD128`<br> 
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
      - ./jellyfin_cache:/cache
      - ./jellyfin_config:/config
      - /mnt/bigdisk/serialy:/media/shows:ro
      - /mnt/bigdisk/filmy_2:/media/movies:ro
    ports:
      - "8096:8096"       # webGUI
      - "1900:1900/udp"   # autodiscovery on local networks
      - "7359:7359/udp"   # autodiscovery on local networks

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

# JELLYFIN

# url or ip address
JELLYFIN_PublishedServerUrl=https://tv.example.com
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


Click through the basic setup. 

* Change the server's name<br>
  `Dashboard` > `General` > `Server name`
* 


<details>
<summary><h1>Intel specific setup</h1></summary>

* [the official documentation](https://jellyfin.org/docs/general/administration/hardware-acceleration/intel/#configure-with-linux-virtualization)

Assuming an intel cpu with an igpu of the last \~8 years.<br>
The `compose.yml` + `.env` should just work.

### Hardware Accelerated Transcoding.

`Dashboard` > `Playback` > `Transcoding`

* `Hardware acceleration` - **Intel QuickSync (QSV)**
* `QSV Device` - `/dev/dri/renderD128`
* `Enable hardware decoding for`
  * Check everything **except** `AV1` and `HEVC RExt 12bit`
  * if 12th gen+ check everything
* `Enable hardware encoding` - check
* `Enable VPP Tone mapping` - check
* `Enable Tone mapping` - check
* `Encoding preset` - `Auto`
* `Throttle Transcodes` - check
* `Delete segments` - check

To be able to use `Enable Intel Low-Power H.264 hardware encoder`

* On the docker host<br>
  `echo "options i915 enable_guc=2" > /etc/modprobe.d/i915.conf`
* `mkinitcpio -P`
* reboot

</details>

---
---

<details>
<summary><h1>AMD specific setup</h1></summary>

* [the official documentation](https://jellyfin.org/docs/general/administration/hardware-acceleration/amd#configure-with-linux-virtualization)
* [some videos](https://youtu.be/H0pCpNT4b-Q) with [some takes](https://youtu.be/UNJLDS5gC7o)
  on [AMD transcoding](https://youtu.be/pnvp9DtqVjo)

Assuming an amd cpu with vega or RDNA.<br>
The `compose.yml` + `.env` should just work.

`Dashboard` > `Playback` > `Transcoding`

* `Hardware acceleration` - **Video Acceleration API (VAAPI)**
* `QSV Device` - `/dev/dri/renderD128`
* `Enable hardware decoding for`
  * Check everything **except** `AV1` and `HEVC RExt 12bit`
  * if 7000+ check everything
* `Enable hardware encoding` - check
  * `Allow encoding in AV1 format` - check if 8000G+
* `Enable Tone mapping` - check, but needs work
* `Encoding preset` - `Auto`
* `Throttle Transcodes` - check
* `Delete segments` - check

Tone mapping

* for my arch host installing these packages<br>
  `sudo pacman -S xf86-video-amdgpu libva-mesa-driver mesa-vdpau vulkan-radeon vulkan-tools`
* reboot

</details>

---
---

<details>
<summary><h1>Mounting network shares</h1></summary>

If the media files are stored and an smb share and should be mounted directly
on the docker host using [systemd mounts](https://forum.manjaro.org/t/root-tip-systemd-mount-unit-samples/1191),
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

</details>

---
---

# Troubleshooting

#### Playback failed due to a fatal player error

![playback_error](https://i.imgur.com/aEjFvra.png)

* docker host - go to `jellyfin/jellyfin_config/log/`
* the last file in the folder is the last playback attempt
* paste that in to chatgpt

#### Autodiscovery not working

to check if autodiscovery port is open and server is responding:

* `echo -n 'Who is JellyfinServer?' | nc -u -b 10.0.19.4 7359`


![error-pic](https://i.imgur.com/KQhmZTQ.png)

#### Unable to connect to the selected server right now

*We're unable to connect to the selected server right now. Please ensure it is running and try again.*

* try opening the url in browsers private window
* if that works then clear the cookies in your browser

#### No playback at all but GUI works fine

Might be no access to network share, for example if dockerhost boots up faster
than NAS.

# Update

Manual image update:

- `docker compose pull`</br>
- `docker compose up -d`</br>
- `docker image prune`

# Useful

* https://www.reddit.com/r/selfhosted/comments/1bit5xr/livetv_on_jellyfin_2024/
