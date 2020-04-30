# Caddy v2 Reverse Proxy

###### guide by example

![logo](https://i.imgur.com/xmSY5qu.png)

# Purpose

Reverse proxy setup that allows hosting many services and access them
based on the host name.</br>
For example nextcloud.blabla.org takes you to your nextcloud file sharing,
and bitwarden.blabla.org takes you to your password manager.

![logo](https://i.imgur.com/rzhNJ23.png)

# Caddy as a reverse proxy in docker

Caddy will be running as a docker container and will route traffic to other containers,
or machines on the network.

### - Requirements

* have a docker host and some vague docker knowledge
* have port 80 and 443 forwarded on the router/firewall to the docker host
* have a domain, `blabla.org`, you can buy one for 2€ annually on namecheap
* have corectly set type-A DNS records pointing at your public IP address,
  preferably using Cloudflare


### - Files and directory structure

```
/home
└── ~
    └── docker
        └── caddy
            ├── [] config
            ├── [] data
            ├── .env
            ├── Caddyfile
            └── docker-compose.yml
```

* `config` - directory containing configs that Caddy generates,
  most notably `autosave.json` which is a json version of the last run `Caddyfile`
* `data` - directory storing TLS certificates
* `.env` - file containing environmental variables for docker compose
* `Caddyfile` - configuration file for Caddy
* `docker-compose.yml` - docker compose file, telling docker how to build Caddy container

The directories are created by docker on the first run, 
the content is visible on only as root of docker host.

### - Create a new docker network

`docker network create caddy_net`
  
All the containers and Caddy must be on the same network.

### - Create .env file

You want to change `blabla.org` to your domain.

`.env`
```bash
MY_DOMAIN=blabla.org
DEFAULT_NETWORK=caddy_net
```
    
Domain names, api keys, email settings, ip addresses, database credentials, ... 
whatever is specific for one deployment and different for another,
all of that ideally goes in to the `.env` file.

If `.env` file is present in the directory with the compose file,
it is automatically loaded and these variables will be available
for docker-compose when building the container with `docker-compose up`.
This allows compose files to be moved from system to system more freely
and changes are done to the `.env` file.

Often variable should be available also inside the running container.
For that it must be declared in the `environment` section of the compose file,
as can be seen next in Caddie's `docker-compose.yml`

*extra info:*</br>
`docker-compose config` shows how compose will look
with the variables filled in.

### - Create docker-compose.yml

`docker-compose.yml`
```yml
version: "3.7"
services:

  caddy:
    image: "caddy/caddy"
    container_name: "caddy"
    hostname: "caddy"
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      - MY_DOMAIN
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./data:/data
      - ./config:/config

networks:
  default:
    external:
      name: $DEFAULT_NETWORK
```

* port 80 and 443 are mapped for http and https
* MY_DOMAIN variable is passed in to the container so that it can be used
  in `Caddyfile`
* the `Caddyfile` is read-only bind-mounted from the docker host
* directories `data` and `config` are bind mounted so that their content persists
* the same network is joined as for all other containers

### - Create Caddyfile

`Caddyfile`
```
{
    # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}

a.{$MY_DOMAIN} {
    reverse_proxy whoami:80
}

b.{$MY_DOMAIN} {
    reverse_proxy nginx:80
}
```

`a` and `b` are the subdomains, can be named whatever.
For them to work they must have type-A DNS record
pointing at your public ip set on Cloudflare, or wherever the domains DNS is managed.</br>
Can also be a wild card `*.blabla.org -> 104.17.436.89`

The value of `{$MY_DOMAIN}` is provided by the compose and the `.env` file.</br>
The subdomains point at docker containers by their **hostname** and **exposed port**.
So every docker container you spin should have hostname definied.</br>
Commented out is the staging url for let's encrypt, useful for testing.

### - Setup some docker containers

Something light and easy to setup to route to.</br>
Assuming for this testing these compose files are in the same directory with Caddy,
so they make use of the same `.env` file and so be on the same network.

Note the lack of published/mapped ports in the compose,
as they will be accessed only through Caddy, which has it's ports published.</br>
And since the containers and Caddy are all on the same bridge docker network,
they can access each other on any port.</br>
Exposed ports are just documentation,
[don't confuse expose and publish](https://maximorlov.com/exposing-a-port-in-docker-what-does-it-do/).

*extra info:*</br>
To know which ports containers have exposed - `docker ps`, or `docker inspect`,
or use [ctop](https://github.com/bcicen/ctop).

`whoami-compose.yml`
```yaml
version: "3.7"
services:

  whoami:
    image: "containous/whoami"
    container_name: "whoami"
    hostname: "whoami"

networks:
  default:
    external:
      name: $DEFAULT_NETWORK
```

`nginx-compose.yml`
```yaml
version: "3.7"
services:

  nginx:
    image: nginx:latest
    container_name: nginx
    hostname: nginx

networks:
  default:
    external:
      name: $DEFAULT_NETWORK
```
### - editing hosts file

You are likely on your local network and you are running docker host
inside the same network.
Without [editing the hosts file,](https://support.rackspace.com/how-to/modify-your-hosts-file/)
shit will not work when trying to access services using domain name. 

so just edit `hosts` as root/administrator,
adding whatever is the local IP of the docker host and the hostname:

  * `192.168.1.222 a.blabla.org`
  * `192.168.1.222 b.blabla.org`

Or use Opera browser and enable the build in VPN if it's for quick testing.

### - Run it all

Caddy

* `docker-compose up -d`

Services

* `docker-compose -f whoami-compose.yml up -d`
* `docker-compose -f nginx-compose.yml up -d`

Give it time to get certificates, checking `docker logs caddy` as it goes,
then visit the urls. It should lead to the services with https working.

If something is fucky use `docker logs caddy` to see what is happening.</br>
Restarting the container `docker container restart caddy` can help.
Or investigate inside `docker exec -it caddy /bin/sh`.
For example trying to ping hosts that are suppose to be reachable,
`ping nginx` should work.

There's also other possible issues, like bad port forwarding towards docker host.

# Caddy more info and various configurations

![caddyfile-diagram-pic](https://i.imgur.com/c0ycNal.png)

Worth reading the official documentation, especially these short pages  

* [reverse_proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy)
* [conventions](https://caddyserver.com/docs/conventions)

Caddy when used as a reverse proxy functions as a [TLS termination proxy](https://www.youtube.com/watch?v=H0bkLsUe3no).</br> 
Https encrypted tunel ends with it, and the traffic can be analyzed 
and dealt with based on the settings.

By default, Caddy passes through Host header and adds X-Forwarded-For
for the client IP.
This means that 90% of the time the simple config just works
    
```
b.blabla.org {
  reverse_proxy server-blue:80
}
```

But there are some cases that want something extra,
as shown in following examples.

### Reverse proxy without names just for LAN

If some containers should be accessed only from LAN with no interest in
domains and https and all that noise.

```
localhost:55414 {
  reverse_proxy urbackup:55414
}

:9090 {
  reverse_proxy prometheus:9090
}
```

Prometheus entry uses short-hand notation.</br>
TLS is automatically disabled in localhost use.

But for this to work Caddy's compose file needs to have those ports **published** too.

`docker-compose.yml`
```yml
version: "3.7"
services:

  caddy:
    image: "caddy/caddy"
    container_name: "caddy"
    hostname: "caddy"
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "55414:55414"
      - "9090:9090"
    environment:
      - MY_DOMAIN
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./data:/data
      - ./config:/config

networks:
  default:
    external:
      name: $DEFAULT_NETWORK
```

With this setup, and assuming docker host at: `192.168.1.222`,
writing `192.168.1.222:55414` in to browser will go to to urbackup,
and `192.168.1.222:9090` gets to prometheus.

### Backend communication

Some containers might be set to communicate only through https 443 port.
But since they are behind proxy, their certificates wont be singed, wont be trusted.

Caddies sub-directive `transport` sets how to communicate with the backend.
Setting port to 443 or declaring `tls` makes it use https.
Setting `tls_insecure_skip_verify` makes Caddy trust whatever certificate
is coming from the backend.

```
example.{$MY_DOMAIN} {
    reverse_proxy {
        to example:443
        transport http {
            tls
            tls_insecure_skip_verify
        }
    }
}
```

### HSTS and redirects

Running Nextcloud behind any proxy likely shows few warning on its status page.
It requires some redirects for service discovery to work and would like 
if [HSTS](https://www.youtube.com/watch?v=kYhMnw4aJTw) would be set.</br> 
Like so:

```
nextcloud.{$MY_DOMAIN} {
    reverse_proxy nextcloud:80
    header Strict-Transport-Security max-age=31536000;
    redir /.well-known/carddav /remote.php/carddav 301
    redir /.well-known/caldav /remote.php/caldav 301
}
```

### gzip and headers

This example is with bitwarden_rs password manager, which comes with its reverse proxy
[recommendations](https://github.com/dani-garcia/bitwarden_rs/wiki/Proxy-examples).

`encode gzip` enables compression.</br>
This lowers the bandwith use and speeds up loading of the sites.
It is often set on the webserver running inside the docker container,
but if not it can be enabled on caddy.
You can check if your stuff has it enabled by using one of
[many online tools](https://varvy.com/tools/gzip/)

Bitwarden also asks for some extra headers.</br>
We can also see its use of websocket protocol for notifications at port 3012.</br>

```
bitwarden.{$MY_DOMAIN} {
    encode gzip

    header / {
        # Enable cross-site filter (XSS) and tell browser to block detected attacks
        X-XSS-Protection "1; mode=block"
        # Disallow the site to be rendered within a frame (clickjacking protection)
        X-Frame-Options "DENY"
        # Prevent search engines from indexing (optional)
        X-Robots-Tag "none"
        # Server name removing
        -Server
    }

    # The negotiation endpoint is also proxied to Rocket
    reverse_proxy /notifications/hub/negotiate bitwarden:80

    # Notifications redirected to the websockets server
    reverse_proxy /notifications/hub bitwarden:3012

    # Proxy the Root directory to Rocket
    reverse_proxy bitwarden:80
}
```

### Logging

[Official documentation.](https://caddyserver.com/docs/caddyfile/directives/log)</br>
If access logs for specific site are desired

```  
bookstack.{$MY_DOMAIN} {
    log {
        output file /data/logs/bookstack_access.log {
            roll_size 20mb
            roll_keep 5
        }
    }
    reverse_proxy to bookstack:80
}
```

# Caddy dns challenge

  Caddy [needs](https://github.com/caddyserver/tls.dns) to be compiled with dns module imported.
  So since this feels like too much work for now, it is untested.

  Benefit of using DNS challenge is being able to to use letsencrypt for https
  even with port 80/443 blocked by ISP. Also being able to use wildcard certificate.

  It could be also useful in security, as Cloudflare offers 5 firewall rules in the free tier.
  Which means one can geoblock any traffic that is not from your own country.</br>
  But I assume Caddy's default HTTP challenge would be also blocked so no certification renewal.</br>
  But with DNS challenge the communication is entirely between letsencrypt
  and Cloudflare.

# Caddy basicauth

[Official documentation.](https://caddyserver.com/docs/caddyfile/directives/basicauth)</br>
If username/password check before accessing a service is required. 
  
Password is [bcrypt](https://www.devglan.com/online-tools/bcrypt-hash-generator) encrypted
and then [base64](https://www.base64encode.org/) hashed.</br>
In this case username and password are *bastard* / *bastard*

`Caddyfile`
```
b.{$MY_DOMAIN} {
    reverse_proxy whoami:80
    basicauth {
      bastard JDJhJDA0JDVkeTFJa1VjS3pHU3VHQ2ZSZ0pGMU9FeWdNcUd0Wk9RdWdzSzdXUXNhWFFLWW5pYkxXVEU2
    }
}
```
