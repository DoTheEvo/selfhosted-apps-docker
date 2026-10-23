# iVentoy

###### guide-by-example

![logo](https://i.imgur.com/DNBoL6f.png)

# Purpose & Overview

PXE network boot tool for OS installation.<br>

* [Official site](https://www.iventoy.com/en/index.html)

Same author as Ventoy, but unlike Ventoy, iVentoy is closed source.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── iVentoy/
            ├── 🗁 data/
            ├── 🗁 log/
            ├── 🗁 user/
            └── 🗋 compose.yml
```              

# Compose

Have your folder with ISOs mounted

`docker-compose.yml`
```yml
services:
  iventoy:
    image: szabis/iventoy:latest
    container_name: iventoy
    hostname: iventoy
    network_mode: host
    privileged: true
    restart: unless-stopped
    volumes:
      - ./data:/opt/iventoy/data   # config + license
      - ./log:/opt/iventoy/log     # logs
      - ./user:/opt/iventoy/user   # autoinstall scripts
      - /mnt/bigdisk/images/ventoy_pack:/opt/iventoy/iso     # ISOs
```

# Network 

![loginpic](https://i.imgur.com/2yxcSZH.png)


not bothering with revere proxy for this,
accesing directly on docker host at port 26000 - http://10.0.19.4:26000

For network boot to work, it's esiest to have a router/dhcp that allows
setting PXE server IP and filename 

filename - `iventoy_loader_16000`

# First run

![loginpic](https://i.imgur.com/GVLkRME.png)

* configuration - DHCP Server Mode - External
* Boot information - check server IP and NIC

**start** the service

# Trouble shooting



# Site-to-Site


# Update

Manual image update:

- `docker compose pull`</br>
- `docker compose up -d`</br>
- `docker image prune`

# Alternative

