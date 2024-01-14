# gotify ntfy signal 

###### guide-by-example

![logo](https://i.imgur.com/ZkGGeT5.png)

# Purpose & Overview

Instant push notifications if email feels old timey and crowded

* [gotify](https://github.com/gotify/server)
* [ntfy](https://github.com/binwiederhier/ntfy)
* [bbernhard/signal-cli-rest-api ](https://github.com/bbernhard/signal-cli-rest-api)

---

# Overview

* **gotify** - great for single person use, but the moment theres more people
  they need to share single account and so lack the ability to choose
  what to get and what not to get.
* **ntfy** - simple original approach to just subscribing to "topics" without
  authentification. Simple single line code for push notification.
  Support for multiple users, supports ios.
* **signal-cli-rest-api** - no gui, needs a sim card, a phone number registred,
  notification are send through that phone number.
  Signal wider spread might make it a winner, since you are not asking people
  to install an another app.

Afte few weeks of tinkering with these... **ntfy is the winner for me**, for now.<br>
Compose files for the other two are at the end.

# docker-compose for ntfy

`docker-compose.yml`
```yml
services:

  ntfy:
    image: binwiederhier/ntfy
    container_name: ntfy
    hostname: ntfy
    env_file: .env
    restart: unless-stopped
    command:
      - serve
    ports:
      - "80:80"
    volumes:
      - ./ntfy_cache:/var/cache/ntfy
      - ./ntfy_etc:/etc/ntfy

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

# Reverse proxy

Caddy is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
ntfy.{$MY_DOMAIN} {
  reverse_proxy ntfy:80
}
```

# The usage

[Documentation](https://docs.ntfy.sh/publish/)

ntfy uses "topics" for categorization, which creates a very handy disconnect from
sender and receiver.<br>
Lets say there's a minecraft server and there are notifications when someone 
joins. These notifications are send to `minecraft` topic, not to specified users.
Users can subscribe to the topic if they want those notifications.
This gives great flexibility and is the main reason why ntfy wins
over other solutions.

#### Linux

`curl -d "a player joined" https://ntfy.example.com/minecraft`

#### Windows

* win10+

  `Invoke-RestMethod -Method 'Post' -Uri https://ntfy.example.com/minecraft -Body "a player joined" -UseBasicParsing`

* win8.1 and older need bit extra for https to work<br>

  ```
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-RestMethod -Method 'Post' -Uri https://ntfy.example.com/minecraft -Body "a player joined" -UseBasicParsing
  ```

#### systemd unit file service

To allows use of ntfy `OnFailure` and `OnSuccess` inside systemd unit files.

To send useful info [specifiers](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Specifiers)
are used.

* %n - full unit name
* %p - prefix part of the name
* %i - instance name, between @ and suffix
* %H - machine hostname

Systemd template unit file is used.
These contains `@` to allow for dynamical naming at runtime.
They are called with additional info added between `@` and the suffix `.service`

`ntfy@.service`
```
[Unit]
Description=ntfy notification service
After=network.target

[Service]
Type=simple
ExecStart=/bin/curl -d "%i | %H" https://ntfy.example.com/systemd
```

Example of a service using the above defined service to send notifications.

`borg.service`
```
[Unit]
Description=BorgBackup docker
OnFailure=ntfy@failure-%p.service
OnSuccess=ntfy@success-%p.service

[Service]
Type=simple
ExecStart=/opt/borg_backup.sh
```

# Grafana to ntfy

![ntfy](https://i.imgur.com/gL81jRg.png)

Alerting in grafana to ntfy works, but its ugly with just json shown.

To solve this 

* Add container [grafana-to-ntfy](https://github.com/kittyandrew/grafana-to-ntfy).
  Set in `.env` ntfy local url
* in grafana set contact point webhook aimed at `http://grafana-to-ntfy:8080`,
  with credentials from the `.env`

`docker-compose.yml`
```yml
services:

  ntfy:
    image: binwiederhier/ntfy:v2.4.0
    container_name: ntfy
    hostname: ntfy
    env_file: .env
    restart: unless-stopped
    command:
      - serve
    ports:
      - "80:80"
    volumes:
      - ./ntfy_cache:/var/cache/ntfy
      - ./ntfy_etc:/etc/ntfy

  grafana-to-ntfy:
    container_name: grafana-to-ntfy
    hostname: grafana-to-ntfy
    image: kittyandrew/grafana-to-ntfy
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "8080:8080"
  

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true

```

`.env`
```php
# GENERAL
DOCKER_MY_NETWORK=caddy_net
TZ=Europe/Bratislava

NTFY_URL=http://ntfy:80/whatever
BAUTH_USER=admin
BAUTH_PASS=test
```

<details>
<summary><h1>gotify and signal compose</h1></summary>

`gotify-docker-compose.yml`
```yml
services:

  gotify:
    image: gotify/server
    container_name: gotify
    hostname: gotify
    restart: unless-stopped
    env_file: .env
    volumes:
      - "./gotify_data:/app/data"

networks:
  default:
    name: caddy_net
    external: true
```

`signal-docker-compose.yml`
```yml
  signal:
    image: bbernhard/signal-cli-rest-api
    container_name: signal
    hostname: signal
    env_file: .env
    restart: unless-stopped
    volumes:
      - "./signal-cli-config:/home/.local/share/signal-cli" #map "signal-cli-config" folder on host system into docker container. the folder contains the password and cryptographic keys when a new number is registered

networks:
  default:
    name: caddy_net
    external: true
```

</details>

---
---
