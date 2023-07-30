# NUT - Network UPS Tools

###### guide-by-example

![logo](https://i.imgur.com/TAIgm4Y.png)

WORK IN PROGRESS<br>
WORK IN PROGRESS<br>
WORK IN PROGRESS<br>

# Purpose & Overview

UPS - uninterruptible power supply managment. Huge drivers support.


* [Official site](https://networkupstools.org/index.html)
* [Github](https://github.com/networkupstools/nut)
* [Archlinux Wiki](https://wiki.archlinux.org/title/Network_UPS_Tools)

The main objective is to be able to shutdown properly larger amount of devices
when power goes out and ups battery starts to get low.

Nut is collection of programs and drivers, mostly written in C. 
For webgui it uses apache webserver.

[Techno Tim youtube video](https://www.youtube.com/watch?v=vyBP7wpN72c)

As per the video I am testing this running on rpi.
[Here's](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/arch_raspberry_pi)
arch on rpi setup.

WORK IN PROGRESS<br>
WORK IN PROGRESS<br>
WORK IN PROGRESS<br>
 
---

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
It's a simpler, single container approach. The 
[complexity](https://github.com/rustdesk/rustdesk-server#classic-image)
of rustdesk's `hbbs` server and `hbbr` relay hidden.

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

In the `.env` file encryption is enabled, so that only clients that have
correct public key will be allowed access to the rustdesk server.<br>
The keys are generated on the first run of the compose and can be found in
the `rustdesk_data` directory.
Once generated they should be added to the `.env` file for easier migration.
The public key needs to be distributed with the clients apps installation.

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
* Three dots > ID/Relay Server
  * `ID Server`: rust.example.com
  * `Key`: *\<content of id_ed25519.pub\>*
* The green dot at the bottom should be green saying "ready".

![settings-pic](https://i.imgur.com/lX6egMH.png)

**On windows** one 
[can deploy](https://rustdesk.com/docs/en/self-host/install/#put-config-in-rustdeskexe-file-name-windows-only)
client with **pre-sets** by renaming the installation file to:
`rustdesk-host=<host-ip-or-name>,key=<public-key-string>.exe`

example: `rustdesk-host=rust.example.com,key=3AVva64bn1ea2vsDuOuQH3i8+2M=.exe`

If by chance the public key contains symbols not usable in windows filenames,
down the container, delete the files `id_ed25519` and `id_ed25519.pub`,
up the container and try with the new keys.

# Extra info

* You really really **really want to be using domain and not your public IP**
  when installing clients and setting ID server. That `rust.example.com`
  can be changed to point at a different IP any time you want. Hard set IP not.
* Can do `tcpdump -n udp port 21116` on a docker host to **see heartbeat** udp traffic.
  Seems machines report-in every \~13 seconds.
* on **windows** a **service** named `rustdesk` is enabled.
  Disable it if the machine should be accessible only on demand,
  when someone first runs rustdesk manually.<br>
  In powershell - `Set-Service rustdesk -StartupType Disabled`
* One can relatively easily
  **hardcode server url and pub key in to an executable** using
  [github actions.](https://rustdesk.com/docs/en/self-host/hardcode-settings/)<br>
  Tested it and it works. But seems you can only do workflow run of nightly build,
  meaning all the latest stuff added is included, which means higher chance of bugs.<br>
  Make sure you do step *"Enable upload permissions for workflows"*, 
  before you run the workflow.
* Questions about issues with selfhosting are **not answered** on github - 
  [#763](https://github.com/rustdesk/rustdesk/discussions/763),
  next to try is their [discord](https://discord.com/invite/nDceKgxnkV) or
  [subreddit](https://www.reddit.com/r/rustdesk/).
* [FAQ](https://github.com/rustdesk/rustdesk/wiki/FAQ)
* How does [rustdesk work?](https://github.com/rustdesk/rustdesk/wiki/How-does-RustDesk-work%3F)

![logo](https://i.imgur.com/ptfVMtJ.png)

# Trouble shooting

---

#### If just one machine is having issues.

uninstall, plus delete:

* `C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk`
* `%AppData%\RustDesk`

Restart. Reinstall.<br>
Do not use the installer you used before, **download** from the site latest.

---

#### Error - Failed to connect to relay server

* I had wrong url set as `RELAY` in the `.env` 
* if url is correct I would test if port 21117 tcp forwards

---

#### Investigate port forwarding

Install netcat and tcpdump on the docker host.

* docker compose down rustdesk container so that ports are free to use
* start a small netcat server listening on whichever port we test<br>
  `sudo nc -u -vv -l -p 21116`<br>
  the `-u` means udp traffic, delete to do tcp
* on a machine somewhere else in the world, not on the same network, try 
  `nc -u <public-ip> 21116`

If you write something and press enter, it should appear on the other machine, confirming
that port forwarding works.<br>
Also useful command can be `tcpdump -n udp port 21116`<br>
When port forwarding works, one should see heartbeat chatter,
as machines with installed rustdesk are announcing themselves every \~13 seconds.

---

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

