# Minecraft server in docker

###### guide-by-example

![logo](https://i.imgur.com/VphJTKG.png)

# Purpose & Overview

A game - open world, building, survival.

* [Official site](https://www.minecraft.net/en-us)
* [itzg github](https://github.com/itzg/docker-minecraft-server)

Minecraft is written in Java.<br>
This setup is using [itzg](https://github.com/itzg/docker-minecraft-server)
maintend docker image. Specificly [Purpur](https://purpurmc.org/docs/)
version which is fork of 
[paper](https://www.spigotmc.org/wiki/what-is-spigot-craftbukkit-bukkit-vanilla-forg/).
Few plugings are used which allow to host multiple worlds on the same server.<br>
Also [docker-rcon-web-admin](https://github.com/itzg/docker-rcon-web-admin) 
container is runnig to be able to do basic console tasks from web interface.

This setup is written in september 2022 with 1.19.2 being the latest build.

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

* `minecraft-data/` - a directory where minecraft stores its data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a compose file, telling docker how to build containers

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
      - 8123:8123
    volumes:
      - ./minecraft-data:/data

  rcon-web:
    image: itzg/rcon
    container_name: rcon-web
    hostname: rcon-web
    restart: unless-stopped
    env_file: .env
    ports:
      - 4326:4326
      - 4327:4327

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

# ITZG MINECRAFT SPECIFIC
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

# ITZG RCON WEB ADMIN SPECIFIC
RWA_USERNAME: admin
RWA_PASSWORD: admin
RWA_ADMIN: "TRUE"
RWA_RCON_HOST: minecraft
# needs to match the password configured for the container, which is 'minecraft' by default
RWA_RCON_PASSWORD: minecraft

```

# Port forwarding

You **must forward port 25565** on your firewall to your docker host
if you want it world accessible.<br>

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

The minecraft server itself does not need this, but plugins do.

First one is dynmap, to see real time map of the world.<br>
Second one is for rcon web admin, to be able to quickly manage server from anywhere.

`Caddyfile`
```
map.{$MY_DOMAIN} {
    reverse_proxy minecraft:8123
}

rcon.{$MY_DOMAIN} {
    reverse_proxy rcon-web:4326
}
```

# Domain 

Setup a DNS A-record for you subdomain - `minecraft.example.com`
Will work fine if using default port `25565`<br>
If you would want to use a different port, but also would prefer your users
to not need to enter `minecraft.example.com:30108` then google 
"minecraft srv record" and you should find correct settings.<br>
Like [this one](https://i.imgur.com/hDhZQ.png).

# Plugins

* [multiverse core](https://dev.bukkit.org/projects/multiverse-core)
* [multiverse portals](https://dev.bukkit.org/projects/multiverse-portals)
* [multiverse inventory](https://dev.bukkit.org/projects/multiverse-inventories)
* [multiverse netherportals](https://dev.bukkit.org/projects/multiverse-netherportals/)
* [EssentialsX](https://essentialsx.net/downloads.html) *(switch to stable tab)*
* [EssentialsX Spawn](https://essentialsx.net/downloads.html)

Why the plugins?<br>
You want one server but you want people to be able to play creative or surival?<br>
Well you need `multiverse core`.<br>
How do the people move between these worlds?<br>
Well you need `multiverse portals`.<br>
Should they be able to bring stuff from one world to another? No?<br>
Well you need `multiverse inventory`.<br>
Should the connecting of worlds with their nether be easy?<br>
Well you need `multiverse netherportals`.<br>
Should they spawn in lobby on connecting,
but also remember the position in the worlds when entering portals?<br>
Well you need the rest of that shit, `EssentialsX` and `EssentialsX Spawn`.

**Plugins installation** - place the downloaded jar files in to 
  `~/docker/minecraft/minecraft-data/plugins`<br>
restart the server

# The setup

check if the plugins are loaded using command `plugins`

### creation of the worlds

* check the worlds present - `mv list`<br>
  these 3 existing worlds [world, nether, end] are grouped and interconnected
  and will be used as the survival world
* create a new world called **"creative_world"** - `mv create creative_world normal`
* teleport to it - `mv tp creative_world`
* switch mode to creative - `mvm set mode creative creative_world`
* create a new world called **"lobby"** - `mv create lobby normal -t flat`
* teleport to lobby world - `mv tp lobby`
* remove monsters - `mvm set difficulty peaceful`
* remove animals - `mv modify set animals false`
* set adventure - `mvm set mode adventure`
* **build 2 portals**, for survival and creative worlds
* get worldedit axe using command - `mvp wand`
* use left click and right click to select portal area<br>
  after selecting it create a portal named portal1 with destination creative_world - 
  `mvp create portal1 creative_world`
* same thing with the axe for survival, with destination to "world" - 
  `mvp create portal2 world`
* you can check your portals configuration on server in `> plugins > multiverse-portals > config.yml`
* if **non OP players** cant use portals execute - 
  `mvp conf enforceportalaccess false` or `mv conf enforceaccess false`

*bonus info*<br>
if you have seed `mv create snow_world normal -s -5343926151482505487`


### spawning in the worlds 
* pick a spawn point in the lobby and set it with multiple commands
* `setspawn`
* `setworldspawn`
* `mv setspawn`
* edit the file in `> plugins > Essentials > config.yml`<br>
  `setspawn-on-join: true`
* you would think we are done with spawns, but nope, fuck you,
  this all lets the game start in spawn location in the lobby world,
  but when entering creative world you would be starting from its spawn,
  instead of last position on exit. So... heres how to fix that.
* this command for the inventory plugin makes the world remember last location
  `mvinv toggle last_location`<br>
  but with just that change the lobby world position is also remembered
  and users end up spawning inside of portals instead of specific spawn
* to fix that we set in `> plugins > multiverse-inventories > config.yml`
  `optionals_for_ungrouped_worlds: false`<br>
* but our lobby world is ungrouped, so we need to add it to a group
  using command `mvinv group` and then following the instructions.
  Writing the answers in to the console without slash, when it asks
  about shares, giving `last_location` and ending with `@`<br>
  [This](https://i.imgur.com/8yBh2Bz.png) could be helpful too,
  but it feels like doing unnecessary steps
* now you should have spawn point in lobby that is always the same,
  while after entering portals you end up at your last location

# Extra Plugins 

* [AntiPopup](https://github.com/KaspianDev/AntiPopup) - 
  if you dont want that stupid chat popup so thats AntiPopup.<br>
* [luckperms](https://luckperms.net/download) - manage permissions of players
* [Action Bar Health](https://www.spigotmc.org/resources/action-bar-health.2661/)
  - see mobs health when you fight them, `show on look` i set to false<br>
  prefered the look of holomobhealth, but its dependancy ProtocolLib is only 
  in beta now, and might be causing issues on my server, did not investigate thoroughly
* [Dynmap](https://www.spigotmc.org/resources/dynmap%C2%AE.274/) - map 
  of the world in web gui, real time. Default port 8123
* [Chunky](https://www.spigotmc.org/resources/chunky.81534/) - pre-generates chunks
  useful for dynmap to fill black patches
* https://www.spigotmc.org/resources/openlogin-1-7x-1-19x.57272/




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
