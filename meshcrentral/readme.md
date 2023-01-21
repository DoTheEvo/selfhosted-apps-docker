# Meshcentral in docker

###### guide-by-example

![logo](https://i.imgur.com/aqBSYbu.png)

# Purpose & Overview

Powerful remote desktop toolset. 

* [Official site](https://www.meshcommander.com/meshcentral2)
* [Github](https://github.com/Ylianst/MeshCentral)
* [ghcr.io](https://github.com/ylianst/MeshCentral/pkgs/container/meshcentral)

Web based, can be a replacement for TeamViewer or Anydesk.<br>
The server is written in javascript, running in node.js runtime.
The client application is written mostly in C runnig Duktape javascript engine.

For database the server uses a build in neDB, which should be enough for
less than 100 clients deployments. Or MongoDB can be deployed for better
performance and robustness but added complexity.

The architecture is relatively simple.

* a server you host is accessible through a web site
* clients can from this site install Mesh Agent
  which allows full control of the device from the servers web

Theres also an entire aspect of possibility of using
Intel AMT - Active Management Technology through port 4433.

---

![interface-pic](https://i.imgur.com/0egkM4J.png)

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── meshcentral/
            ├── meshcentral/
            ├── .env
            └── docker-compose.yml
```

* `meshcentral/` - persistent data, most notable is config.json in data\
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the two files.</br>
The directories are created by docker compose on the first run.

# docker-compose

The official docker image is hosted [on github.](https://github.com/ylianst/MeshCentral/pkgs/container/meshcentral)
More info [here](https://github.com/Ylianst/MeshCentral/tree/master/docker)<br>
This setup goes more robust way, with a separate container running mongodb.

`docker-compose.yml`
```yml
services:

  meshcentral-db:
    image: mongo:latest
    container_name: meshcentral-db
    hostname: meshcentral-db
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./meshcentral/mongodb_data:/data/db

  meshcentral:
    image: ghcr.io/ylianst/meshcentral:latest
    container_name: meshcentral
    hostname: meshcentral
    restart: unless-stopped
    env_file: .env
    depends_on:
      - meshcentral-db
    volumes:
      # config.json and other important files live here. A must for data persistence
      - ./meshcentral/data:/opt/meshcentral/meshcentral-data
      # where file uploads for users live
      - ./meshcentral/user_files:/opt/meshcentral/meshcentral-files
      # location for the meshcentral-backups - this should be mounted to an external storage
      - ./meshcentral/backup:/opt/meshcentral/meshcentral-backup
      # location for site customization files
      - ./meshcentral/web:/opt/meshcentral/meshcentral-web

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

# MESHCENTRAL
NODE_ENV=production

# initial mongodb-variables
MONGO_INITDB_ROOT_USERNAME=mongodbadmin
MONGO_INITDB_ROOT_PASSWORD=mongodbpasswd

# initial meshcentral-variables
# the following options are only used if no config.json exists in the data-folder

# your hostname
HOSTNAME=mesh.example.com
USE_MONGODB=true
# set to your reverse proxy IP if you want to put meshcentral behind a reverse proxy 
REVERSE_PROXY=example.com
REVERSE_PROXY_TLS_PORT=443
# set to true if you wish to enable iframe support
IFRAME=false
# set to false if you want disable self-service creation of new accounts besides the first (admin)
ALLOW_NEW_ACCOUNTS=true
# set to true to enable WebRTC - per documentation it is not officially released with meshcentral and currently experimental. Use with caution
WEBRTC=false
# set to true to allow plugins
ALLOWPLUGINS=false
# set to true to allow session recording
LOCALSESSIONRECORDING=false
# set to enable or disable minification of json, reduces traffic
MINIFY=true
```

Bit of an issue is that the official project expects to find the database
at the hostname `mongodb`. It's hardcoded in the
[startup.sh](https://github.com/Ylianst/MeshCentral/blob/master/docker/startup.sh)
which on first run generates `config.json`.<br> 
This is not ideal as one likely will run several containers and 
undescriptive container name or hostname is annoying.<br>

To deal with this, **run it first time for few minutes, then down it, edit the** 
`.\meshcentral\data\config.json` and change the mongoDb line to look like this:

    "settings": {
      "mongoDb": "mongodb://mongodbadmin:mongodbpasswd@meshcentral-db:27017",
    },

if meshcentral container shows: *ERROR: Unable to parse /opt/meshcentral/meshcentral-data/config.json*<br>
you need to down it, delete the `meshcentral` with the persistent data,
and up it again, now let it run longer before downing and editing the database path.

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
mesh.{$MY_DOMAIN} {
    reverse_proxy meshcentral:443 {
        transport http {
            tls
            tls_insecure_skip_verify
        }
    }
}
```

---

![interface-pic](https://i.imgur.com/CK6pRyq.png)

# The usage on clients

# Improved safety


# Trouble shooting

# Running without separate database

`docker-compose.yml`
```yml
services:

  meshcentral:
    image: ghcr.io/ylianst/meshcentral:latest
    container_name: meshcentral
    hostname: meshcentral
    restart: unless-stopped
    env_file: .env
    volumes:
      # config.json and other important files live here. A must for data persistence
      - ./meshcentral/data:/opt/meshcentral/meshcentral-data
      # where file uploads for users live
      - ./meshcentral/user_files:/opt/meshcentral/meshcentral-files
      # location for the meshcentral-backups - this should be mounted to an external storage
      - ./meshcentral/backup:/opt/meshcentral/meshcentral-backup
      # location for site customization files
      - ./meshcentral/web:/opt/meshcentral/meshcentral-web

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

# MESHCENTRAL
NODE_ENV=production

# initial mongodb-variables
MONGO_INITDB_ROOT_USERNAME=mongodbadmin
MONGO_INITDB_ROOT_PASSWORD=mongodbpasswd

# initial meshcentral-variables
# the following options are only used if no config.json exists in the data-folder

# your hostname
HOSTNAME=mesh.example.com
USE_MONGODB=false
# set to your reverse proxy IP if you want to put meshcentral behind a reverse proxy 
REVERSE_PROXY=example.com
REVERSE_PROXY_TLS_PORT=443
# set to true if you wish to enable iframe support
IFRAME=false
# set to false if you want disable self-service creation of new accounts besides the first (admin)
ALLOW_NEW_ACCOUNTS=true
# set to true to enable WebRTC - per documentation it is not officially released with meshcentral and currently experimental. Use with caution
WEBRTC=false
# set to true to allow plugins
ALLOWPLUGINS=false
# set to true to allow session recording
LOCALSESSIONRECORDING=false
# set to enable or disable minification of json, reduces traffic
MINIFY=true
```



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

