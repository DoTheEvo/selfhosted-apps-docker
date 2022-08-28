# Minecraft server in docker

###### guide-by-example

![logo](https://i.imgur.com/GYq1N1l.png)

# Purpose & Overview

Open world building and surviving game.

* [Official site](https://www.minecraft.net/en-us)
* [Github](https://github.com/itzg/docker-minecraft-server)

Minecraft is written in Java.

[Purpur](https://purpurmc.org/docs/) version of the server
is used in this setup along with few plugings,
which allow to host multiple worlds on the same server.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── minecraft/
            ├── minecraft-data/
            ├── .env
            └── docker-compose.yml
```

* `minecraft-data/` - a directory where bookstack will store its web app data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the files.</br>
The directory is created by docker compose on the first run.

# docker-compose

`docker-compose.yml`
```yml
services:
  minecraft:
    image: itzg/minecraft-server
    container_name: minecraft
    hostname: minecraft
    restart: unless-stopped
    env_file: .env
    tty: true
    stdin_open: true
    ports:
      - 25565:25565
    volumes:
      - ./minecraft-data:/data
```

`.env`
```bash
# GENERAL
MY_DOMAIN=example.com
DOCKER_MY_NETWORK=caddy_net
TZ=Europe/Bratislava

# itzg specific
TYPE=PURPUR
EULA=TRUE
ONLINE_MODE=FALSE
SNOOPER_ENABLED=FALSE
SERVER_NAME=Blablabla
ALLOW_CHEATS=TRUE
MAX_MEMORY=3G
MAX_PLAYERS=50
ENABLE_COMMAND_BLOCK=TRUE
ALLOW_NETHER=TRUE
OVERRIDE_ICON=TRUE
ICON=https://i.imgur.com/cjwKzqi.png

```

# Reverse proxy

No need. There is no website managment.
There is no accessing it through port 80 or 443.
Just clients connecting through port 25565
and that does not go through reverse proxy.
But you **must forwarded 25565** on your firewall to your docker host.

# Plugins

This setup is written in august 2022<br>
1.19.2 is the latest build

* [multiverse core](https://dev.bukkit.org/projects/multiverse-core)
* [multiverse portals](https://dev.bukkit.org/projects/multiverse-portals)
* [multiverse inventory](https://dev.bukkit.org/projects/multiverse-inventories)
* [EssentialsX](https://essentialsx.net/downloads.html)
* [EssentialsX Spawn](https://essentialsx.net/downloads.html)

Why the mods and what purpose?<br>
You wanna one server but you want people to be able to play creative or surival>
Well you need multiverse core.<br>
How do the people move between these worlds?<br>
Well you need multiverse portals and have "lobby world".<br>
Can they bring stuff from one world to another? No?<br>
Well you need multiverse inventory.<br>
Do you want them to spawn in lobby on connecting,
but remember also the position in the worlds when entering their portals?<br>
Well you need the rest of that shit, EssentialsX and EssentialsX Spawn.<br>

here go specific instructions when I do it again on fresh install





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

* down the minecraft container `docker-compose down`</br>
* delete the entire minecraft directory</br>
* from the backup copy back the minecraft directory</br>
* start the containers `docker-compose up -d`
