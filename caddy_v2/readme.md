# Caddy v2 Reverse Proxy

###### guide-by-example

![logo](https://i.imgur.com/xmSY5qu.png)


1. [Purpose & Overview](#Purpose--Overview)
2. [Caddy as a reverse proxy in docker](#Caddy-as-a-reverse-proxy-in-docker)
3. [Caddy more info and various configurations](#Caddy-more-info-and-various-configurations)
4. [Caddy DNS challenge](#Caddy-DNS-challenge)

# Purpose & Overview

Reverse proxy setup that allows hosting many services and access them
based on the host name.<br>
For example `nextcloud.example.com` takes you to your nextcloud file sharing,
and `bitwarden.example.com` takes you to your password manager,
all hosted on your local network.

* [Official site](https://caddyserver.com/v2)
* [Official documentation](https://caddyserver.com/docs/)
* [Forum](https://caddy.community/)
* [Github](https://github.com/caddyserver/caddy)

Caddy is a powerful, enterprise-ready, open source web server with automatic
HTTPS written in Go.<br>
Web servers are build to deal with http traffic, so they are an obvious choice
for the function of reverse proxy.

In this setup Caddy is used mostly as
[a TLS termination proxy](https://www.youtube.com/watch?v=H0bkLsUe3no).<br> 
Https encrypted tunel ends with it, so that the traffic can be analyzed 
and send to a correct webserver based on the settings in `Caddyfile`.

Caddy with its build-in https and and simple config approach
allows even most trivial configs to just work:
    
```
whatever.example.com {
  reverse_proxy server-blue:80
}

blabla.example.com {
  reverse_proxy 192.168.1.20:80
}
```

![url](https://i.imgur.com/rzhNJ23.png)

# Caddy as a reverse proxy in docker

Caddy will be running as a docker container and will route traffic to other containers,
or machines on the network.

### - Requirements

* have some basic linux knowledge, create folders, create files, edit files, run scripts,...
* have a docker host and some vague docker knowledge
* have port 80 and 443 forwarded on the router/firewall to the docker host
* have a domain, `example.com`, you can buy one for 2€ annually on namecheap
* have corectly set type-A DNS records pointing at your public IP address,
  preferably using Cloudflare


### - Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── caddy/
            ├── config/
            ├── data/
            ├── .env
            ├── Caddyfile
            └── docker-compose.yml
```

* `config/` - a directory containing configs that Caddy generates,
  most notably `autosave.json` which is a backup of the last loaded config
* `data/` - a directory storing TLS certificates
* `.env` - a file containing environment variables for docker compose
* `Caddyfile` - the Caddy configuration file
* `docker-compose.yml` - a docker compose file, telling docker how to run containers

You only need to provide the three files.<br>
The directories are created by docker compose on the first run, 
the content of these is visible only as root of the docker host.

### - Create a new docker network

`docker network create caddy_net`
  
All the containers and Caddy must be on the same network.

### - Create .env file

You want to change `example.com` to your domain.

`.env`
```bash
MY_DOMAIN=example.com
DOCKER_MY_NETWORK=caddy_net
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

*extra info:*<br>
`docker-compose config` shows how compose will look
with the variables filled in.

### - Create docker-compose.yml

`docker-compose.yml`
```yml
version: "3.7"
services:

  caddy:
    image: caddy
    container_name: caddy
    hostname: caddy
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
      name: $DOCKER_MY_NETWORK
```

* port 80 and 443 are pusblished for http and https
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
pointing at your public ip set on Cloudflare, or wherever the domains DNS is managed.<br>
Can also be a wild card `*.example.com -> 104.17.436.89`

The value of `{$MY_DOMAIN}` is provided by the compose and the `.env` file.<br>
The subdomains point at docker containers by their **hostname** and **exposed port**.
So every docker container you spin should have hostname definied.<br>
Commented out is the staging url for let's encrypt, useful for testing.

### - Setup some docker containers

Something light and easy to setup to route to.<br>
Assuming for this testing these compose files are in the same directory with Caddy,
so they make use of the same `.env` file and so be on the same network.

Note the lack of published/mapped ports in the compose,
as they will be accessed only through Caddy, which has it's ports published.<br>
And since the containers and Caddy are all on the same bridge docker network,
they can access each other on any port.<br>
Exposed ports are just documentation,
[don't confuse expose and publish](https://maximorlov.com/exposing-a-port-in-docker-what-does-it-do/).

*extra info:*<br>
To know which ports containers have exposed - `docker ps`, or
`docker port <container-name>`, or use [ctop](https://github.com/bcicen/ctop).

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
      name: $DOCKER_MY_NETWORK
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
      name: $DOCKER_MY_NETWORK
```
### - editing hosts file

You are on your local network and you are likely running the docker host
inside the same network.<br>
If that's the case then shit will not work without editing the hosts file.<br> 
Reason being that when you write that `a.example.com` in to your browser,
you are asking google's DNS for `a.example.com` IP address.
It will give you your own public IP, and most routers/firewalls wont allow
this loopback, where your requests should go out and then right back.

So just [edit](https://support.rackspace.com/how-to/modify-your-hosts-file/)
`hosts` as root/administrator,
adding whatever is the local IP of the docker host and the hostname:

```
192.168.1.222     a.example.com
192.168.1.222     b.example.com
```

If it is just quick testing one can use Opera browser
and enable the build in VPN.<br>

One can also run a dns/dhcp server on the network, to solve this for all
devices.<br>
Here's a [guide-by-example for dnsmasq](
https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/dnsmasq).

### - Run it all

Caddy

* `docker-compose up -d`

Services

* `docker-compose -f whoami-compose.yml up -d`
* `docker-compose -f nginx-compose.yml up -d`

Give it time to get certificates, checking `docker logs caddy` as it goes,
then visit the urls. It should lead to the services with https working.

If something is fucky use `docker logs caddy` to see what is happening.<br>
Restarting the container `docker container restart caddy` can help.
Or investigate inside `docker exec -it caddy /bin/sh`.
For example trying to ping hosts that are suppose to be reachable,
`ping nginx` should work.

There's also other possible issues, like bad port forwarding towards docker host.

*extra info:*<br>
`docker exec -w /etc/caddy caddy caddy reload` reloads config
if you made changes and want them to take effect.

# Caddy more info and various configurations

##### Caddyfile structure:  

![caddyfile-diagram-pic](https://i.imgur.com/c0ycNal.png)

Worth having a look at the official documentation, especially these short pages  

* [concept](https://caddyserver.com/docs/caddyfile/concepts)
* [conventions](https://caddyserver.com/docs/conventions)
* [reverse_proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy)

Maybe checking out
[mozzila's - overview of HTTP](https://developer.mozilla.org/en-US/docs/Web/HTTP/Overview)
would also not hurt, it is very well written.

### Routing traffic to other machines on the LAN

If not targeting a docker container but a dedicated machine on the network.<br>
Nothing really changes, if you can ping the machine from Caddy container
by its hostname or its IP, it will work. 

```
blue.{$MY_DOMAIN} {
  reverse_proxy server-blue:80
}

violet.{$MY_DOMAIN} {
  reverse_proxy 192.168.1.100:80
}
```

### Reverse proxy without domain and https

You can always just use localhost, which will translates in to docker hosts IP address.

```
localhost:55414 {
  reverse_proxy urbackup:55414
}

:9090 {
  reverse_proxy prometheus:9090
}
```

Prometheus entry uses short-hand notation.<br>
TLS is automatically disabled in localhost use.

But for this to work Caddy's compose file needs to have those ports **published** too.

`docker-compose.yml`
```yml
version: "3.7"
services:

  caddy:
    image: caddy
    container_name: caddy
    hostname: caddy
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
      name: $DOCKER_MY_NETWORK
```

With this setup, and assuming docker host at: `192.168.1.222`,
writing `192.168.1.222:55414` in to browser will go to to urbackup,
and `192.168.1.222:9090` gets to prometheus.

### Named matchers and IP filtering

Caddy has [matchers](https://caddyserver.com/docs/caddyfile/matchers)
which allow you to define how to deal with incoming requests.<br>
`reverse_proxy server-blue:80` is a matcher that matches all requests
and sends them somewhere.<br>
But if more control is desired, path matchers and named matchers come to play.

What if you want to block all traffic coming from the outside world,
but local network be allowed through?<br>
Well, the [remote_ip](https://caddyserver.com/docs/caddyfile/matchers#remote-ip)
matcher comes to play, which enables you to filter requests by their IP.<br>

Named matchers are defined by `@` and can be named whatever you like.

```
{
    # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}

a.{$MY_DOMAIN} {
    reverse_proxy whoami:80
}

b.{$MY_DOMAIN} {
    reverse_proxy nginx:80

    @fuck_off_world {
        not remote_ip 192.168.1.0/24
    }
    respond @fuck_off_world 403
}
```

`@fuck_off_world` matches all IPs except the local network IP range.<br>
Requests matching that rule get the response 403 - forbidden.

### Snippets

What if you need to have the same matcher in several site-blocks and
would prefer for config to look cleaner? 

Here comes the [snippets](https://caddyserver.com/docs/caddyfile/concepts#snippets).<br>
Snippets are defined under the global options block,
using parentheses, named whatever you like.<br>
They then can be used inside any site-block with simple `import <snippet name>`

Now would be a good time to look again at that concept picture above.

Here is above example of IP filtering named matcher done using a snippet.

```
{
    # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}

(LAN_only) {
    @fuck_off_world {
        not remote_ip 192.168.1.0/24
    }
    respond @fuck_off_world 403
}

a.{$MY_DOMAIN} {
    reverse_proxy whoami:80
}

b.{$MY_DOMAIN} {
    reverse_proxy nginx:80
    import LAN_only
}
```

### Backend communication

Some containers might be set to communicate only through https 443 port.
But since they are behind proxy, their certificates wont be singed, wont be trusted.

Caddies sub-directive `transport` sets how to communicate with the backend.<br>
Setting the upstream's scheme to `https://`
or declaring the `tls` transport subdirective makes it use https.
Setting `tls_insecure_skip_verify` makes Caddy ignore errors due to
untrusted certificates coming from the backend.

```
whatever.{$MY_DOMAIN} {
    reverse_proxy https://server-blue:443 {
        transport http {
            tls
            tls_insecure_skip_verify
        }
    }
}
```

### HSTS and redirects

Here is an example of a redirect when wanting the common case of
switching anyone that comes to a `www` subdomain to the naked domain.

```
www.{$MY_DOMAIN} {
    redir https://{$MY_DOMAIN}{uri}
}
```

Another example is running NextCloud behind proxy,
which likely shows few warning on its status page.
It requires some redirects for service discovery to work and would like 
if [HSTS](https://www.youtube.com/watch?v=kYhMnw4aJTw) would be set.<br> 
Like so:

```
nextcloud.{$MY_DOMAIN} {
    reverse_proxy nextcloud:80
    header Strict-Transport-Security max-age=31536000;
    redir /.well-known/carddav /remote.php/carddav 301
    redir /.well-known/caldav /remote.php/caldav 301
}
```

### Headers and gzip

This example is with bitwarden_rs password manager, which comes with its reverse proxy
[recommendations](https://github.com/dani-garcia/bitwarden_rs/wiki/Proxy-examples).

`encode gzip` enables compression.<br>
This lowers the bandwith use and speeds up loading of the sites.
It is often set on the webserver running inside the docker container,
but if not it can be enabled on caddy.
You can check if your stuff has it enabled by using one of
[many online tools](https://varvy.com/tools/gzip/)

By default, Caddy passes through Host header and adds X-Forwarded-For
for the client IP. This means that 90% of the time a simple config
is all that is needed but sometimes some extra headers might be desired.

Here we see bitwarden make use of some extra headers.<br>
We can also see its use of websocket protocol for notifications at port 3012.

```
bitwarden.{$MY_DOMAIN} {
    encode gzip

    header {
        # Enable cross-site filter (XSS) and tell browser to block detected attacks
        X-XSS-Protection "1; mode=block"
        # Disallow the site to be rendered within a frame (clickjacking protection)
        X-Frame-Options "DENY"
        # Prevent search engines from indexing (optional)
        X-Robots-Tag "none"
        # Server name removing
        -Server
    }

    # Notifications redirected to the websockets server
    reverse_proxy /notifications/hub bitwarden:3012

    # Proxy the Root directory to Rocket
    reverse_proxy bitwarden:80
}
```

### Basic authentication

[Official documentation.](https://caddyserver.com/docs/caddyfile/directives/basicauth)<br>
Directive `basicauth` can be used when one needs to add
a username/password check before accessing a service. 

Password is [bcrypt](https://www.devglan.com/online-tools/bcrypt-hash-generator) hashed
and then [base64](https://www.base64encode.org/) encoded.<br>
You can use the [`caddy hash-password`](https://caddyserver.com/docs/command-line#caddy-hash-password)
command to hash passwords for use in the config.

Config bellow has login/password : `bastard`/`bastard`

`Caddyfile`
```
b.{$MY_DOMAIN} {
    reverse_proxy whoami:80
    basicauth {
        bastard JDJhJDA0JDVkeTFJa1VjS3pHU3VHQ2ZSZ0pGMU9FeWdNcUd0Wk9RdWdzSzdXUXNhWFFLWW5pYkxXVEU2
    }
}
```

### Logging

[Official documentation.](https://caddyserver.com/docs/caddyfile/directives/log)<br>
If access logs for specific site are desired

```  
bookstack.{$MY_DOMAIN} {
    log {
        output file /data/logs/bookstack_access.log {
            roll_size 20mb
            roll_keep 5
        }
    }
    reverse_proxy bookstack:80
}
```

# Caddy DNS challenge

This setup only works for Cloudflare.

Benefit of using DNS challenge is being able to to use Let's Encrypt for HTTPS
even with port 80/443 inaccessible from outside networks.

Also allows for issuance of wildcard certificates.
Though with the free Cloudflare tier, wildcard record is not proxied,
so your public IP is exposed.

It could be also useful in security,
as Cloudflare offers 5 firewall rules in the free tier.
Which means one can geoblock any traffic that is not from your own country.<br>
But I assume Caddy's default HTTP challenge would be also blocked,
so no certification renewal.<br>
But with DNS challenge the communication is entirely between Let's Encrypt
and Cloudflare servers.

### - Create API token on Cloudflare

On Cloudflare create a new API Token with two permsisions,
[pic of it here](https://i.imgur.com/YWxgUiO.png)

* zone/zone/read<br>
* zone/dns/edit<br>

Include all zones needs to be set.

### - Create Dockerfile

To add support, Caddy needs to be compiled with
[Cloudflare DNS plugin](https://github.com/caddy-dns/cloudflare).<br>
This is done by using your own Dockerfile, using the `builder` image.

Create a directory `dns-dockerfile` in the caddy directory.<br>
Inside create a file named `Dockerfile`.

`Dockerfile`
```Dockerfile
FROM caddy:2.0.0-builder AS builder

RUN caddy-builder \
    github.com/caddy-dns/cloudflare

FROM caddy:2.0.0

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
```

### - Edit .env file

Add `CLOUDFLARE_API_TOKEN` variable with the value of the newly created token.

`.env`
```
MY_DOMAIN=example.com
DOCKER_MY_NETWORK=caddy_net

CLOUDFLARE_API_TOKEN=<cloudflare api token goes here>
```

### - Edit docker-compose.yml

`image` replaced with `build` option pointing at the `Dockerfile` location<br>
and `CLOUDFLARE_API_TOKEN` variable added.

`docker-compose.yml`
```yml
version: "3.7"
services:

  caddy:
    build: ./dns-dockerfile
    container_name: caddy
    hostname: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      - MY_DOMAIN
      - CLOUDFLARE_API_TOKEN
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./data:/data
      - ./config:/config

networks:
  default:
    external:
      name: $DOCKER_MY_NETWORK
```


### - Edit Caddyfile

Add `tls` directive to the site-blocks, forcing the use of tls dns challange.

`Caddyfile`
```
{
    # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}

a.{$MY_DOMAIN} {
    reverse_proxy whoami:80
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
}

b.{$MY_DOMAIN} {
    reverse_proxy nginx:80
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
}
```

