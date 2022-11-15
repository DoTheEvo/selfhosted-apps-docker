# Rustdesk in docker

###### guide-by-example

![logo](https://i.imgur.com/ImsIffW.png)

# Purpose & Overview

Remote desktop application. 

* [Official site](https://rustdesk.com/)
* [Github](https://github.com/rustdesk/rustdesk)
* [DockerHub](https://hub.docker.com/r/rustdesk/rustdesk-server)

Rustdesk is a young opensource replacement for TeamViewer or Anydesk.
The major thing is that it does NAT punching, 
and lets you host all the infrastructure for it to function.

Written in rust(gasp), with Dart and Flutter framework for client side.</br>

![interface-pic](https://i.imgur.com/ekA7Hms.png)

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── rustdesk/
            ├── data/
            ├── .env
            └── docker-compose.yml
```

* `data/` - relay server
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the two files.</br>
The directory is created by docker compose on the first run.

# docker-compose

Using edited version of [S6-overlay based images.](https://github.com/rustdesk/rustdesk-server#s6-overlay-based-images)<br>
It's a simpler, single container approach, without the noise of hbbs/hbbr.


`docker-compose.yml`
```yml
services:
  rustdesk:
    image: rustdesk/rustdesk-server-s6:latest
    container_name: rustdesk
    hostname: rustdesk
    restart: unless-stopped
    env_file: .env
    ports:
      - 21115:21115
      - 21116:21116
      - 21116:21116/udp
      - 21117:21117
      - 21118:21118
      - 21119:21119
    volumes:
      - ./data:/data

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true
```

`.env`
```bash
# GENERAL
MY_DOMAIN=example.com
DOCKER_MY_NETWORK=caddy_net
TZ=Europe/Bratislava

# RUSTDESK
RELAY=rust.example.com:21117
ENCRYPTED_ONLY=0
```

# Port forwarding

ports 21115 - 21119 needs to be open for tcp<br>
the port 21116 also udp

# The Usage

* download and install the client apps from [the official site](https://rustdesk.com/)
* three dots near ID > ID/Relay Server > ID Server: rust.example.com > OK
* the green dot at the bottom should stay green saying "ready"
* done
* in the docker server logs you should see machines public IP and ID code it was given

To delete rustdesk data from a windows machine, delete:

* `C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk`
* `%AppData%\RustDesk`

# Encrypted use

![settings-pic](https://i.imgur.com/6mKkSuh.png)

For encrypted communication and to prevent undesirables access to the server

* they encryption public key is on the docker host:<br>
  `~/docker/rustdesk/data/id_ed25519.pub`
* you can manually add it to any client application<br>
  three dots near ID > ID/Relay Server > Key: 3AVva64bn1ea2vsDuOuQH3i8+2M=
* to only allow clients with the key on server:<br>
  in the env_file set `ENCRYPTED_ONLY=1`

[On windows](https://rustdesk.com/docs/en/self-host/install/#put-config-in-rustdeskexe-file-name-windows-only)
one can deploy client with these settings by renaming
the installation file to: `rustdesk-host=<host-ip-or-name>,key=<public-key-string>.exe`

example: `rustdesk-host=rust.example.com,key=3AVva64bn1ea2vsDuOuQH3i8+2M=.exe`

If by chance the key contains symbols not usable in windows filenames,
down the container, delete the files `id_ed25519` and `id_ed25519.pub`, up the container
---

# Trouble shooting



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

