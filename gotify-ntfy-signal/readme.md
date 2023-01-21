# gotify ntfy signal 

###### guide-by-example

![logo](https://i.imgur.com/41WzW04.png)

# Purpose & Overview

Instant notifications if email feels old timey and crowded

* [gotify](https://github.com/gotify/server)
* [ntfy](https://github.com/binwiederhier/ntfy)
* [bbernhard/signal-cli-rest-api ](https://github.com/bbernhard/signal-cli-rest-api)

---

# Overview

* **gotify** - great for single person use, but the moment theres more people
  they need to share single account and so lack the ability to choose
  what to get and what not to get
* **ntfy** - simple original approach to just subscribing to "topics" without
  authentification, very simple one line push notification.
  Drawback is rather high [battery consumption](https://i.imgur.com/TDhj7El.jpg)
  of the android app, but I did not let it run for long enough it could also
  just be my phone thing. Just something to keep an eye on.
* **signal-cli-rest-api** - no gui, need a sim card phone number registred,
  worse concept for sending notification to multiple users,
  where you need to manually set everyone who should receive,
  as oppose to having a "room/topic" to which one can "susbscribe",
  but if signal is widespread enough and you are not asking people to install
  another app then its a winner

# docker-compose

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

`ntfy-docker-compose.yml`
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
    volumes:
      - ./ntfy-cache:/var/cache/ntfy
      - ./ntfy-etc:/etc/ntfy

networks:
  default:
    name: $DOCKER_MY_NETWORK
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
    name: $DOCKER_MY_NETWORK
    external: true
```

# Port forwarding

# The usage on clients

# Encrypted use


# Trouble shooting

# Update

# Backup and restore

#### Backup
  
#### Restore


