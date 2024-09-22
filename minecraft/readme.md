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
version which is a fork of 
[Paper](https://www.spigotmc.org/wiki/what-is-spigot-craftbukkit-bukkit-vanilla-forg/)
 which is a fork of [Spigot](https://www.spigotmc.org/wiki/what-is-spigot-craftbukkit-bukkit-vanilla-forg/).
Few plugings are used which allow to host multiple worlds on the same server.<br>

This setup is written in september 2022 with 1.19.2 being the latest build.<br>
Small edits still go on as of september 2024.

Worth note is that [Crafty](https://craftycontrol.com/) exists,
and seems pretty damn good.<br>
[This video](https://youtu.be/bAGTwBURBXc) is what made me interested,
but did not try it yet beyond just simple spin and try when playing with
[casaOS](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/beginners-speedrun-selfhosting).

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── minecraft/
            ├── 🗁 minecraft_data/
            ├── 🗋 .env
            └── 🗋 docker-compose.yml
```

* `minecraft_data/` - a directory where minecraft stores its data
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
      - 25565:25565     # minecraft server players connect
      - 8100:8100       # bluemap
      - 8123:8123       # dynmap
    volumes:
      - ./minecraft_data:/data
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"

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
```

# Port forwarding

You **must forward port 25565** on your firewall to your docker host
if you want it world accessible.<br>
[Here's](https://github.com/DoTheEvo/selfhosted-apps-docker/blob/master/_knowledge-base/port_forwarding.md) a detailed guide.

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

The minecraft server itself does not need this, but plugins might.<br>
Like lets say dynmap would answer at `map.example.com`

`Caddyfile`
```
map.{$MY_DOMAIN} {
    reverse_proxy minecraft:8123
}
```

# Domain 

Setup a DNS A-record for you subdomain - `minecraft.example.com`
Will work fine if using default port `25565`<br>
If you would want to use a different port, but also would prefer your users
to not need to enter `minecraft.example.com:30108` then google 
"minecraft srv record" and you should find correct settings.<br>
Like [this one](https://i.imgur.com/hDhZQ.png).

# Monitoring

[How to monitor minecraft server using prometheus, loki, granana.](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/prometheus_grafana_loki)

# Plugins

**Plugins installation** - place the downloaded jar files in to 
  `~/docker/minecraft/minecraft_data/plugins` and restart the container.

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
Should they spawn in lobby on start,
but also remember the position in the worlds when entering portals?<br>
Well you need the rest of that shit, `EssentialsX` and `EssentialsX Spawn`.



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
* [Action Bar Health](https://www.spigotmc.org/resources/action-bar-health.2661/)
  - see mobs health when you fight them,
  in config I set `show on look` to false<br>
  I prefered the look of holomobhealth, but its dependancy ProtocolLib is only 
  in beta at the moment, and might be causing issues on my server, did not investigate thoroughly
* [Bluemap](https://www.spigotmc.org/resources/bluemap.83557/) - map 
  of the world in web gui, real time.Default port 8100

----------

Something of this is causing server to ocasionally go to super high disk use
and needs restart. Not just container, but entire VM. Will maybe investigate.

/update, it was likely caused by using m.2 ssd for storing esxi VMs,
switch to sata ssd seems to prevent any more occurancies of this high disk usage

/update2, well since it started happening again, now it seems to be solved
by setting up 6GB swapfile, which I.. err.. didnt think it needed.

* [Dynmap](https://www.spigotmc.org/resources/dynmap%C2%AE.274/) - map 
  of the world in web gui, real time. Default port 8123
* [Chunky](https://www.spigotmc.org/resources/chunky.81534/) - pre-generates chunks
  useful for dynmap to fill black patches
* [OpeNLogin](https://www.spigotmc.org/resources/openlogin-1-7x-1-19x.57272/)
* [luckperms](https://luckperms.net/download) - manage permissions of players,
  planned to use, not in use yet. [Here](https://www.youtube.com/watch?v=AwbVqSOn2SI) is a good video on it.

  luckpers commands 

  * `lp editor` - open browser editor, afterwards it should be confirmed
  * set everything in browser
  * in game `lp user Dunco parent set hráč`


* wordguard with word edit, followed [this video](https://youtu.be/pYAk38Hekqg)

# Comamnds & settings

* `/gamerule playersSleepingPercentage 1` - use bed whenever, sleep not dependant on other players
* to import a map, download, extract, copy the directory to minecraft_data<br>
  `mv import <directory-name> normal`, there should be no spaces in the name
* `/mv setspawn` sets spawn point in the current world

* [command block basics](https://www.youtube.com/watch?v=Mp3UJs9v2_0)

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
