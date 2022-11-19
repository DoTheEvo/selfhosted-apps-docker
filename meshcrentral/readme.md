# Meshcentral in docker

###### guide-by-example

![logo](https://i.imgur.com/aqBSYbu.png)

# Purpose & Overview

Powerful remote desktop toolset. 

* [Official site](https://www.meshcommander.com/meshcentral2)
* [Github](https://github.com/Ylianst/MeshCentral)
* [unofficial DockerHub](https://hub.docker.com/r/typhonragewind/meshcentral)

Web based, can be a replacement for TeamViewer or Anydesk.<br>
The server is written in javascript, running in node.js runtime.
The client application is written mostly in C runnig Duktape javascript engine.

The architecture is relatively simple.<br>

* a server is running online, with ports 80/443 open
* clients can visit the servers web and from it install Mesh Agent
  which allows full control of the device straight from servers webpage

For database the server uses a build in neDB, which should be enough for
less than 100 clients deployments. Or MongoDB can be deployed for better
performance and robustness but added complexity.

---


![interface-pic](https://i.imgur.com/0egkM4J.png)

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── meshcentral/
            ├── data/
            ├── meshcentral/
            ├── .env
            └── docker-compose.yml
```

* `data/` - persistent data for the MongoDB database
* `meshcentral/` - web app persistent data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the two files.</br>
The directories are created by docker compose on the first run.

# docker-compose

There is no official docker image.
So [This one is used.](https://github.com/Typhonragewind/meshcentral-docker)

Going with the more robust MongoDB version.

`docker-compose.yml`
```yml
services:
    meshcentral_db:
        image: mongo:latest
        container_name: meshcentral_db
        hostname: meshcentral_db
        restart: unless-stopped
        expose:
            - 27017
        volumes:
            - ./meshcentral_db:/data/db
    meshcentral:
        image: typhonragewind/meshcentral:mongodb
        container_name: meshcentral
        hostname: meshcentral
        restart: unless-stopped
        env_file: .env
        depends_on:
            - meshcentral_db
        volumes:
            - ./meshcentral/data:/opt/meshcentral/meshcentral-data
            - ./meshcentral/user_files:/opt/meshcentral/meshcentral-files

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
HOSTNAME=mesh.example.com
REVERSE_PROXY=10     #set to your reverse proxy IP
REVERSE_PROXY_TLS_PORT=443
IFRAME=false #set to true if you wish to enable iframe support
ALLOW_NEW_ACCOUNTS=false    
WEBRTC=false  #set to true to enable WebRTC - per documentation it is not officially released with meshcentral, but is solid enough to work with. Use with caution
NODE_ENV=production
```

# Port forwarding

as can be seen in the compose

* **21115 - 21119** TCP need to be forwarded to docker host<br>
* **21116** is TCP and UDP 

21115 is used for the NAT type test,
21116/UDP is used for the ID registration and heartbeat service,
21116/TCP is used for TCP hole punching and connection service,
21117 is used for the Relay services,
and 21118 and 21119 are used to support web clients. 

[source](https://rustdesk.com/docs/en/self-host/install/)

---

![interface-pic](https://i.imgur.com/CK6pRyq.png)

# The usage on clients


* download and install the client apps from [the official site](https://rustdesk.com/)
* three dots near ID > ID/Relay Server > ID Server: rust.example.com > OK
* the green dot at the bottom should stay green saying "ready"
* done
* in the docker server logs you should see machines public IP and ID code it was given

# Encrypted use

![settings-pic](https://i.imgur.com/6mKkSuh.png)

For encrypted communication and to prevent undesirables access to the server

* the encryption public key is on the docker host:<br>
  `~/docker/rustdesk/data/id_ed25519.pub`
* you can manually add it to any client application<br>
  three dots near ID > ID/Relay Server > Key: 3AVva64bn1ea2vsDuOuQH3i8+2M=
* to only allow clients with the key on server:<br>
  in the env_file set `ENCRYPTED_ONLY=1` and down/up the compose.

[On windows](https://rustdesk.com/docs/en/self-host/install/#put-config-in-rustdeskexe-file-name-windows-only)
one can deploy client with these settings pre-set by renaming
the installation file to: `rustdesk-host=<host-ip-or-name>,key=<public-key-string>.exe`

example: `rustdesk-host=rust.example.com,key=3AVva64bn1ea2vsDuOuQH3i8+2M=.exe`

If by chance the public key contains symbols not usable in windows filenames,
down the container, delete the files `id_ed25519` and `id_ed25519.pub`,
up the container

# Trouble shooting

From what I read, most client side issues come from two differently set rustdesk
client applications running on the same machine.<br>

Uninstall/remove all, plus delete:

* `C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk`
* `%AppData%\RustDesk`

restart and do fresh client install

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

