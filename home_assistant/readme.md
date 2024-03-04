# Home Assistant

###### guide-by-example

![logo](https://i.imgur.com/lV7LdOC.png)

# Purpose & Overview

WORK IN PROGRESS<br>
WORK IN PROGRESS<br>
WORK IN PROGRESS<br>

Home monitoring and automation system.

* [Official site](https://www.home-assistant.io/)
* [Github](https://github.com/home-assistant)

HA is designed to be a central control platform for IoT - Internet of Things.
You buy some sensors for movement, temperature, light, door, power consumption,...
you buy some smart light switches, lighbulbs, locks, blinds, relays, microphones,...<br>
And HA lets you automate. If movement happens in room X, switch on light Y,
If temperature drops below X turn on relay Y. If doors X are open send push
notification to user Z. 

HA is open source, written in python.

# Hardware

I picked **Zigbee** for my main wireless protocol.

* **Zigbee** - Cheap to get in to, widespread selection of devices. 
  But uses 2.4Ghz same as wifi so there's chance for
  [interference](https://www.metageek.com/training/resources/zigbee-wifi-coexistence/).
* **Z-Wave** - 900Mhz means great penetration and no wifi interference.
  More reliable compatibility between devices.
  But several times more expensive and poorer selection of devices.
* **Wifi** - Cheapest to get in to as people have wifi. But should not be long
  term plan. It is though prefered for wireless devices that stream nonstop data,
  like let's say a smart powerplug that reports power consumption.
  It saves on limited bandwidth that Zigbee or Z-Wave have.

I got:

* [ZigStar UZG-01](https://uzg.zig-star.com/product/) as the zigbee coordinator, bought from elecrow.
* 3x [Philips Hue Motion Sensor](https://www.philips-hue.com/en-gb/p/hue-hue-motion-sensor/8719514342125) (P/N: 929003067501)


# Installation

* [Official documentation](https://www.home-assistant.io/installation/)

## Docker vs Virtual Machine

Its not really a decision, you want to **go full Virtual Machine.**<br>
Reason being that addons that are essential are installed as docker containers
in to the HA, and there is no way to nest it inside HA when running as a container itself.

I have ESXI hypervisor and I just followed the instructions.

Some core steps.

* [download vmdk](https://www.home-assistant.io/installation/windows)
* Create a new VM - Linux; **Debian 11 x64**; 2 cpus; 4G ram<br>
* Remove disk and dvdrom; add existing disk we dl; switch to IDE 0
* Network adapter switch from VMXnet3 to E1000e
* in VM Options switch from BIOS to EFI

I had some issues when I did not get it right during creation and tried to change
afterwards. The VM would not see the disk. But fresh creation worked
with debian 11 x64 set.

# The Initial Configuration

### First login

* Log in at the `<ipaddress-that-the-VM-got>:8123`
* Create new user and password.
* Set location.
* Set either static IP address in Settings > System > Network<br>
  or set IP reservation on your dhcp server.

### User preferences

change date format and first day of the week, enable advanced mode

### SSH  

* Install addon - Advanced SSH & Web Terminal
* In the configuration set username and copy paste full public key from `.ssh/id_rsa.pub`

### Useful addons

* VSCode

### Reverse proxy

Caddy is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```bash
home.{$MY_DOMAIN} {
    reverse_proxy homeassistant:8123
}
``` 

adding to `configuration.yaml`, either by ssh and nano or VSCode addon

```yml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.0.19.4

homeassistant:
  external_url: "https://home.example.com:8123"
```



# old mess shit beyond this point

---
---
---
---
---
---


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
