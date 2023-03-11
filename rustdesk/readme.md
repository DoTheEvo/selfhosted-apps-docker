# Rustdesk in docker

###### guide-by-example

![logo](https://i.imgur.com/ImsIffW.png)

# Purpose & Overview

Remote desktop access. 

* [Official site](https://rustdesk.com/)
* [Github](https://github.com/rustdesk/rustdesk)
* [DockerHub for S6](https://hub.docker.com/r/rustdesk/rustdesk-server-s6)

Rustdesk is a new fully opensource alternative for TeamViewer or Anydesk.<br>
The major aspects are that it does NAT punching, 
and lets you host all the infrastructure for it to function.<br>
Written in rust(gasp), with Dart and Flutter framework for client side.</br>

The idea is:

* Run a rustdesk server reachable online.
* Install clients on machines you want to connect from / to.
* The clients application keeps a regular heartbeat communication
  with the server, in a way to [punch a hole](https://youtu.be/S7Ifw5XsypQ)
  in the NAT and so allows connection initialized from the outside,
  without doing port forwarding.
 
---

![interface-pic](https://i.imgur.com/ekA7Hms.png)

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── rustdesk/
            ├── 🗁 rustdesk_data/
            ├── 🗋 .env
            └── 🗋 docker-compose.yml
```

* `rustdesk_data/` - persistent data, contains sqlite database and the keys
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the two files.</br>
The directory is created by docker compose on the first run.

# docker-compose

Using [S6-overlay](https://github.com/rustdesk/rustdesk-server#s6-overlay-based-images)
based image.<br>
It's a simpler, single container approach. The complexity of hbbs/hbbr hidden.
It also has health check implemented.

No network section since no http traffic that would need reverse proxy, yet.<br>
So just mapped ports on to docker host to do their thing.

`docker-compose.yml`
```yml
services:
  rustdesk:
    image: rustdesk/rustdesk-server-s6:1.1.7-1
    container_name: rustdesk
    hostname: rustdesk
    restart: unless-stopped
    env_file: .env
    ports:
      - "21116:21116"
      - "21115:21115"
      - "21116:21116/udp"
      - "21117:21117"
      - "21118:21118"
      - "21119:21119"
    volumes:
      - ./rustdesk_data:/data
```

`.env`
```bash
# GENERAL
TZ=Europe/Bratislava

# RUSTDESK
RELAY=rust.example.com:21117
ENCRYPTED_ONLY=1
# KEY_PRIV=<put here content of ./rustdesk_data/id_ed25519>
# KEY_PUB=<put here content of ./rustdesk_data/id_ed25519.pub>
```

In the `.env` file encryption only is enabled, so that only clients that have
correct public key will be allowed access to the rustdesk server.<br>
The keys are generated on the first run of the compose and can be found in
`rustdesk_data` directory. Once generated they should be added to the `.env` file
for easier migration. The public key will need to be distributed with
the clients apps install.

# Port forwarding

as can be seen in the compose

* **21115 - 21119** TCP need to be forwarded to docker host<br>
* **21116** is TCP **and UDP**

21115 is used for the NAT type test,
21116/UDP is used for the ID registration and heartbeat service,
21116/TCP is used for TCP hole punching and connection service,
21117 is used for the Relay services,
and 21118 and 21119 are used to support web clients.<br>
[source](https://rustdesk.com/docs/en/self-host/install/)

---

![interface-pic](https://i.imgur.com/CK6pRyq.png)

# The installation on clients

* Download and install the client apps from [the official site](https://rustdesk.com/).
* Three dots > `ID/Relay Server`. 
  * `ID Server`: rust.example.com
  * `Key`: *\<content of id_ed25519.pub\>*
* The green dot at the bottom should be green saying "ready".

![settings-pic](https://i.imgur.com/lX6egMH.png)

**On windows** one [can](https://rustdesk.com/docs/en/self-host/install/#put-config-in-rustdeskexe-file-name-windows-only)
deploy client with **pre-sets** by renaming the installation file to:
`rustdesk-host=<host-ip-or-name>,key=<public-key-string>.exe`

example: `rustdesk-host=rust.example.com,key=3AVva64bn1ea2vsDuOuQH3i8+2M=.exe`

If by chance the public key contains symbols not usable in windows filenames,
down the container, delete the files `id_ed25519` and `id_ed25519.pub`,
up the container and try with the new keys.

# Extra info

* You really really **really want to be using domain and not your public IP**
  when installing clients and setting ID server. That domain can be changed
  to different IP any time you want. Hard set IP not.
* `tcpdump -n udp port 21116` to **see heartbeat** udp traffic, seems machines 
  report-in every \~13 seconds.
* on **windows** machine a **service** named `rustdesk` is enabled.
  Disable it if want machine accessible only on demand,
  when someone first runs rustdesk.<br>
  In powershell - `Set-Service rustdesk -StartupType Disabled`
* You wont get much response on github if questions is around selfhosting. 
  [#763](https://github.com/rustdesk/rustdesk/discussions/763),
  maybe trying [their discord.](https://discord.com/invite/nDceKgxnkV)

# Trouble shooting

#### If just one machine is having issues.

uninstall, plus delete:

* `C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk`
* `%AppData%\RustDesk`

Restart. Reinstall.<br>
Do not use the installer you used before, **download** from the site latest.

---

#### Error - Failed to connect to relay server

* I had wrongly set in `.env` variable `RELAY`
* generally issue might be with port 21117

---

#### Investigate port forwarding

Install netcat and tcpdump on the docker host.

* docker compose down rustdesk container so that ports are free to use
* start small netcat server listening on whichever port we test<br>
  `sudo nc -u -vv -l -p 21116`<br>
  the `-u` means udp traffic, delete to do tcp
* on a machine somewhere else in the world, not on the same network, try 
  `nc -u <public-ip> 21116`

If you start writing something, it should appear on the other machine, confirming
that port forwarding works.<br>
Also useful command can be `tcpdump -n udp port 21116`<br>
When port forwarding works, one should see heartbeat chatter,
as machines with installed rustdesk are announcing themselves every \~13 seconds.

# Manual image update:

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

