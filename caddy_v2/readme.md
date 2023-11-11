# Caddy v2 Reverse Proxy

###### guide-by-example

![logo](https://i.imgur.com/HU4kHCj.png)

1. [Purpose & Overview](#Purpose--Overview)
2. [Caddy as a reverse proxy in docker](#Caddy-as-a-reverse-proxy-in-docker)
3. [Caddy more info and various configurations](#Caddy-more-info-and-various-configurations)
4. [Caddy DNS challenge](#Caddy-DNS-challenge)
5. [Monitoring](#monitoring)
6. [Other guides](#other-guides)

# Purpose & Overview

Reverse proxy is needed if one wants access to services based on the hostname.<br>
For example `nextcloud.example.com` points traffic to nextcloud docker container,
while `jellyfin.example.com` points to the media server on the network.

* [Official site](https://caddyserver.com/v2)
* [Official documentation](https://caddyserver.com/docs/)
* [Forum](https://caddy.community/)
* [Github](https://github.com/caddyserver/caddy)

Caddy is a pretty damn good web server with automatic HTTPS. Written in Go.

Web servers are build to deal with http traffic, so they are the obvious choice
for the function of reverse proxy. In this setup Caddy is used mostly as
[a TLS termination proxy](https://www.youtube.com/watch?v=H0bkLsUe3no). 
Https encrypted tunel ends with it, so that the traffic can be analyzed 
and send to a correct webserver based on the settings in `Caddyfile`.

Caddy with its build-in automatic https allows configs to be clean and simple
and to just work.

```
nextcloud.example.com {
  reverse_proxy nextcloud-web:80
}

jellyfin.example.com {
  reverse_proxy 192.168.1.20:80
}
```

And **just works** means fully works. No additional configuration needed 
for https redirect, or special services if target is not a container,
or need to deal with load balancer, or need to add boilerplate headers
for x-forward, or other extra work.<br>
It has great out of the box defaults, fitting majority of uses
and only some special casess with extra functionality need extra work.

![url](https://i.imgur.com/iTjzPc0.png)

# Caddy as a reverse proxy in docker

Caddy will be running as a docker container, will be in charge of ports 80 and 443,
and will route traffic to other containers, or machines on the network.

### - Create a new docker network

`docker network create caddy_net`

All the future containers and Caddy must be on this new network.
  
Can be named whatever you want, but it must be a new custom named network.
Otherwise [dns resolution would not work](https://docs.docker.com/network/drivers/bridge/)
and containers would not be able to target each other just by the hostname.

### - Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── caddy/
            ├── 🗁 caddy_config/
            ├── 🗁 caddy_data/
            ├── 🗋 .env
            ├── 🗋 Caddyfile
            └── 🗋 docker-compose.yml
```

* `caddy_config/` - a directory containing configs that Caddy generates,
  most notably `autosave.json` which is a backup of the last loaded config
* `caddy_data/` - a directory storing TLS certificates
* `.env` - a file containing environment variables for docker compose
* `Caddyfile` - Caddy configuration file
* `docker-compose.yml` - a docker compose file, telling docker how to run containers

You only need to provide the three files.<br>
The directories are created by docker compose on the first run, 
the content of these is visible only as root of the docker host.

### - Create docker-compose.yml and .env file

Basic simple docker compose, using the official caddy image.<br>
Ports 80 and 443 are pusblished/mapped on to docker host as Caddy
is the one in charge of any traffic coming there.<br>

`docker-compose.yml`
```yml
services:

  caddy:
    image: caddy
    container_name: caddy
    hostname: caddy
    restart: unless-stopped
    env_file: .env
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./caddy_config:/config
      - ./caddy_data:/data

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true
```

`.env`
```php
# GENERAL
TZ=Europe/Bratislava
DOCKER_MY_NETWORK=caddy_net
MY_DOMAIN=example.com
```

You obviously want to change `example.com` to your domain.


### - Create Caddyfile

`Caddyfile`
```
a.{$MY_DOMAIN} {
    reverse_proxy whoami:80
}

b.{$MY_DOMAIN} {
    reverse_proxy nginx:80
}
```

`a` and `b` are the subdomains, can be named whatever.<br>
For them to work they **must have type-A DNS record set**, that points
at your public ip set on Cloudflare, or wherever the domains DNS is managed.<br>

Can test if correctly set with online dns lookup tools,
[like this one.](https://mxtoolbox.com/DNSLookup.aspx)

The value of `{$MY_DOMAIN}` is provided by the `.env` file.<br>
The subdomains point at docker containers by their **hostname** and **exposed port**.
So every docker container you spin should have hostname definied and be on 
`caddy_net`.<br>

<details>
<summary><h3>Setup some docker containers</h3></summary>

Something light to setup to route to that has a webpage to show.<br>
Not bothering with an `.env` file here.

Note the lack of published/mapped ports in the compose,
as they will be accessed only through Caddy, which has it's ports published.<br>
Containers on the same bridge docker network can access each other on any port.<br>

*extra info:*<br>
To know which ports containers have exposed - `docker ps`, or
`docker port <container-name>`, or use [ctop](https://github.com/bcicen/ctop).

`whoami-compose.yml`
```yaml
services:

  whoami:
    image: "containous/whoami"
    container_name: "whoami"
    hostname: "whoami"

networks:
  default:
    name: caddy_net
    external: true
```

`nginx-compose.yml`
```yaml
services:

  nginx:
    image: nginx:latest
    container_name: nginx
    hostname: nginx

networks:
  default:
    name: caddy_net
    external: true
```

</details>

---
---

<details>
<summary><h3>Editing hosts file</h3></summary>

If the docker host is with you on your local network then you need to deal
with bit of an issue.
When you write that `a.example.com` in to your browser, you are asking 
internet DNS server for IP address of `a.example.com`.
DNS servers will reply with your own public IP, and most consumer routers
wont allow this loopback, where your requests should go out and then right back.

So just [edit](https://support.rackspace.com/how-to/modify-your-hosts-file/)
`hosts` as root/administrator,
adding whatever is the local IP of the docker host and the hostname:

```
192.168.1.222     a.example.com
192.168.1.222     b.example.com
```

You can test what are the replies for DNS requests with the command
`nslookup a.example.com`, works in linux and windows.

If it is just quick testing one can use Opera browser
and enable its build in VPN.<br>

This edit of a host file works only on that one machine.
To solve it for all devices theres need to to run dns server on the network,
or running a higher tier firewall/router.  
* [Here's](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/dnsmasq)
  a guide-by-example for dnsmasq.
* [Here's](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/opnsense)
  a guide-by-example for opnsense firewall

[Here's more details](https://help.mikrotik.com/docs/display/ROS/NAT#NAT-HairpinNAT)
on hairpin NAT reflection concept.

</details>

---
---

### - Run it all

Run all the containers.

Give Caddy time to get certificates, checking `docker logs caddy` as it goes,
then visit the urls. It should lead to the services with https working.

If something is fucky use `docker logs caddy` to see what is happening.<br>
Restarting the container `docker container restart caddy` can help.
Or investigate inside `docker exec -it caddy /bin/sh`.
For example trying to ping hosts that are suppose to be reachable,
`ping nginx` should work.

There's also other possible issues, like bad port forwarding towards docker host,
or ISP not providing you with publicly reachable IP.

*extra info:*<br>
`docker exec -w /etc/caddy caddy caddy reload` reloads config
if you made changes and want them to take effect.

*extra info2:*<br>
caddy can complain about formatting of the `Caddyfile`<br>
this executed on the host will let caddy overwrite the Caddyfile with 
correct formatting
`docker exec -w /etc/caddy caddy caddy fmt -overwrite`  

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

### Disable automatic TLS certificates and https

One might want to use reverse proxy without buying a domain, and without opening
ports to the world, just for general easier access to some services.<br>
For this [auto_https](https://caddyserver.com/docs/caddyfile/options#auto-https)
directive in global options section can be used.
But also what's needed is explicitly state `http:\\` in the address,
or explicitly state port `80`.<br>
[This post](https://caddy.community/t/making-sense-of-auto-https-and-why-disabling-it-still-serves-https-instead-of-http/9761)
well describes how it works.

```
{
  auto_https off
}

http://example.com {
  reverse_proxy server-blue:80
}

test.example.com:80 {
  reverse_proxy 192.168.1.100:80
}
```

What's also needed, is a way for your browser to be send to docker-host's
ip address when `example.com` is entered as url.<br>
So you need to either edit machines host file, or run DNS server on you
network.<br>
*extra info:* `nslookup example.com` shows to what IP address domain goes

### Redirect

Here is an example of a redirect for the common case of switching anyone that
comes to `www.example.com` to the naked domain `example.com`

```php
www.{$MY_DOMAIN} {
    redir https://{$MY_DOMAIN}{uri}
}
```

Or what if theres a need for a short url for something often used, but selfhosted
url-shorterners seem bloated... looking at you Shlink and Kutt.<br>
So lets say you want `down.example.com` to take you straight away to some 
publicly shared download on your nextcloud.

```php
down.{$MY_DOMAIN} {
    redir https://nextcloud.example.com/s/CqJyOijYeezESQT/download
}
```

or if prefering doing path instead of subdomain,
so that it would be `example.com/down`

```php
{$MY_DOMAIN} {
    reverse_proxy whoami:80
    redir /down https://nextcloud.example.com/s/CqJyOijYeezESQT/download
}
```

Another example is running NextCloud behind proxy,
which likely shows few warning on its status page.
These require some redirects for service discovery to work and would like 
if [HSTS](https://www.youtube.com/watch?v=kYhMnw4aJTw)
[2](https://www.youtube.com/watch?v=-MWqSD2_37E) would be set.<br> 
Like so:

```php
nextcloud.{$MY_DOMAIN} {
    reverse_proxy nextcloud:80
    header Strict-Transport-Security max-age=31536000;
    redir /.well-known/carddav /remote.php/carddav 301
    redir /.well-known/caldav /remote.php/caldav 301
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

### Named matchers and IP filtering

Caddy has [matchers](https://caddyserver.com/docs/caddyfile/matchers)<br>

* `*` to match all requests (wildcard; default).
* `/path` start with a forward slash to match a request path.
* `@name` to specify a named matcher.

In `reverse_proxy server-blue:80` matcher is ommited and in that case
the default - `*` applies meaning all traffic.
But if more control is desired, path matchers and named matchers come to play.

What if all traffic coming from the outside world should be blocked, but local
network be allowed through?<br>
Well, the [remote_ip](https://caddyserver.com/docs/caddyfile/matchers#remote-ip)
matcher comes to play, which enables you to filter requests by their IP.<br>

* *Note:* If your router uses hairpin/NATreflection to get around
  [the issue](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2#editing-hosts-file)
  of accessing locally hosted stuff from LAN side by the hostname,
  then this will block LAN side too. As remote_ip will be your public ip.
  Local DNS server is needed, with records sending traffic to docker host
  instead of hairpin/NATreflection.

* *Note:* A shortcut `private_ranges` can be used, instead of specific range.

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

Here come [snippets](https://caddyserver.com/docs/caddyfile/concepts#snippets).<br>
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

### Headers and gzip

This example is with vaultwarden password manager, which comes with its reverse proxy
[recommendations](https://github.com/dani-garcia/vaultwarden/wiki/Proxy-examples).

`encode gzip` enables compression.<br>
This lowers the bandwith use and speeds up loading of the sites.
It is often set on the webserver running inside the docker container,
but if not it can be enabled on caddy.
You can check if your stuff has it enabled by using one of
[many online tools](https://varvy.com/tools/gzip/)

By default, Caddy passes through Host header and adds X-Forwarded-For
for the client IP. This means that 90% of the time a simple config
is all that is needed but sometimes some extra headers might be desired.

Here we see vaultwarden make use of some extra headers.<br>
We can also see its use of websocket protocol for notifications at port 3012.

```
vault.{$MY_DOMAIN} {
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
    reverse_proxy /notifications/hub vaultwarden:3012

    # Proxy the Root directory to Rocket
    reverse_proxy vaultwarden:80
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

### Logging - Access log

[Official documentation.](https://caddyserver.com/docs/caddyfile/directives/log)<br>
Very useful and powerful way to get info on who is accessing what.

Already bind mounted `./caddy_data:/data` directory will be used to store the logs.<br>
A snippet is used so that config is cleaner as logging in caddy
is done per site block, so every block needs to import it, but it allows
separation of logs per domain/subdomain if desired.

```php
(log_common) {
  log {
    output file /data/logs/caddy_access.log {
      roll_size 20mb
      roll_keep 5
    }
  }
}

map.{$MY_DOMAIN} {
  import log_common
  reverse_proxy minecraft:8100
}
```

In the monitoring section theres more use of logging and visualizing it in grafana.

# Caddy DNS challenge

This setup only works for Cloudflare.

DNS challenge authenticates ownership of the domain by requesting that the owner
puts a specific TXT record in to the domains DNS zone.<br>
Benefit of using DNS challenge is that there is no need for your server
to be reachable by the letsencrypt servers. Cant open ports or want to exclude
entire world except your own country from being able to reach your server?
DNS challange is what you want to use for https then.<br>
It also allows for issuance of wildcard certificates.<br>
The drawback is a potential security issue, since you are creating a token
that allows full control over your domain's DNS. You store this token somewhere,
you are giving it to some application from dockerhub...

*Note:* caddy uses a new [libdns](https://github.com/libdns/libdns/)
golang library with [cloudflare package](https://github.com/libdns/cloudflare)

### - Create API token on Cloudflare

[On Cloudflare](https://dash.cloudflare.com/profile/api-tokens)
create a new API Token with two permsisions,
[pic of it here](https://i.imgur.com/YWxgUiO.png)

* zone/zone/read<br>
* zone/dns/edit<br>

Include all zones needs to be set.

### - Edit .env file

Add `CLOUDFLARE_API_TOKEN` variable with the value of the newly created token.

`.env`
```
MY_DOMAIN=example.com
DOCKER_MY_NETWORK=caddy_net

CLOUDFLARE_API_TOKEN=<cloudflare api token goes here>
```

### - Create Dockerfile

To add support, Caddy needs to be compiled with
[Cloudflare DNS plugin](https://github.com/caddy-dns/cloudflare).<br>
This is done by using your own Dockerfile, using the `builder` image.

Create a directory `dockerfile-caddy` in the caddy directory.<br>
Inside create a file named `Dockerfile`.

`Dockerfile`
```Dockerfile
FROM caddy:2.6.2-builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare

FROM caddy:2.6.2

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
```

### - Edit docker-compose.yml

`image` replaced with `build` option pointing at the `Dockerfile` location<br>
and `CLOUDFLARE_API_TOKEN` variable added.

`docker-compose.yml`
```yml
services:

  caddy:
    build: ./dockerfile-caddy
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
      - ./caddy_data:/data
      - ./caddy_config:/config

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true
```


### - Edit Caddyfile

Add global option `acme_dns`<br>
or add `tls` directive to the site-blocks.

`Caddyfile`
```php
{
  acme_dns cloudflare {$CLOUDFLARE_API_TOKEN}
}

a.{$MY_DOMAIN} {
    reverse_proxy whoami:80
}

b.{$MY_DOMAIN} {
    reverse_proxy nginx:80
    tls {
        dns cloudflare {$CLOUDFLARE_API_TOKEN}
    }
}
```

### - Wildcard certificate

A one certificate to rule all subdomains. But not apex/naked domain, thats separate.<br>
As shown in [the documentation](https://caddyserver.com/docs/caddyfile/patterns#wildcard-certificates),
the subdomains must be moved under the wildcard site block and make use
of host matching and handles.


`Caddyfile`
```
{
  acme_dns cloudflare {$CLOUDFLARE_API_TOKEN}
}

{$MY_DOMAIN} {
    reverse_proxy homer:8080
}

*.{$MY_DOMAIN} {
    @a host a.{$MY_DOMAIN}
    handle @a {
        reverse_proxy whoami:80
    }

    @b host b.{$MY_DOMAIN}
    handle @b {
        reverse_proxy nginx:80
    }

    handle {
        abort
    }
}
```

[Here's](https://github.com/caddyserver/caddy/issues/3200) some discussion
on this and a simple, elegant way we could have had, without the need to
dick with the Caddyfile this much. Just one global line declaration.
But the effort went sideways.<br>
So I myself do not even bother with wildcard when the config ends up looking
complex and ugly.

# Monitoring

![dashboards](https://i.imgur.com/dMfxVQy.png)

Prometheus, Grafana, Loki, Promtail are one way ot to get some sort of monitoring
of Caddie's performance and logs, create dashboards from these data,
like a geomap of IPs tha access caddy, and set up allerts for some events,...

Complete guide how to get it up for Caddie is part of of:

* [Prometheus + Grafana + Loki guide-by-example](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/prometheus_grafana_loki#caddy-reverse-proxy-monitoring)


# Other guides

* [gurucomputing caddy guide](https://blog.gurucomputing.com.au/reverse-proxies-with-caddy/)
* 
