# Caddy v2 Reverse Proxy

###### guide by example

![logo](https://i.imgur.com/xmSY5qu.png)


# Caddy as a reverse proxy - basics

[Official documentation.](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy)

- **Install caddy v2**

- **Create Caddyfile**</br>
  The configuration file for caddy. This one with just two subdomains
  being routed to some two services on the LAN.

    `Caddyfile`
    ```
    a.blabla.org {
        reverse_proxy {
            to 192.168.1.222:80
        }
    }

    b.blabla.org {
        reverse_proxy server-blue:8080
    }
    ```

  b.blabla.org uses short hand notation when there are no other directives used.

- **Run caddy server**</br>
  `sudo caddy run` in the directory with Caddyfile.

  Give it time to get certificates and then check
  the a.blabla.org / b.blabla.org</br>
  It should just work with https and http->https redirect.

# Caddy as a reverse proxy in docker

  Caddy will be running as a docker container and will route traffic to other containers,
  or servers on the network.

- **files and directory structure**

    ```
    /home
    └── ~
        └── docker
            └── caddy
                ├── 🗁 config
                ├── 🗁 data
                ├── 🗋 .env
                ├── 🗋 Caddyfile
                └── 🗋 docker-compose.yml
    ```

- **Create a new docker network**</br> `docker network create caddy_net`</br>
  All the containers and caddy must be on the same network.

- **Create `.env` file**</br>

    `.env`
    ```
    MY_DOMAIN=blabla.org
    DEFAULT_NETWORK=caddy_net
    TZ=Europe/Prague
    ```
    
  Domain names, api keys, email settings, ip addresses, database credentials, ... 
  whatever is specific for one case and different for another,
  all of that ideally goes in to the `.env` file.</br>

  These variables will be available for docker-compose when running
  the `docker-compose up` command.</br>
  This allows compose files to be moved from system to system more freely
  and changes are done to the `.env` file.

  Often variable should be available also inside the running container.
  For that it must be declared in the `environment` section of the compose file,
  as can be seen later in caddie's `docker-compose.yml`

  *extra info:*</br>
  `docker-compose config` shows how compose will look
  with the variables filled in.</br>

- **Create docker-compose.yml for caddy**</br>

    `docker-compose.yml`
    ```
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

  Port 80 and 443 are mapped for http and https.</br>
  The `Caddyfile` is read-only bind-mounted from the docker host.</br>
  Directories `config` and `data` are also bind mounted and its where caddy
  will store configuration in json format and the certificates.</br>
  The same network is joined as for all other containers.

- **Create Caddyfile**</br>

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

  The value of `{$MY_DOMAIN}` is an enviromental variable provided
  by the compose and the `.env` file.</br>
  The subdomains point at docker containers by their **hostname** and **port**.
  So every docker container you spin should have hostname definied.</br>
  Commented out is the staging url for let's encrypt, useful for testing.

- **Setup some docker containers**</br>
  Something to route to, targeted using the **hostname** and the **exposed port**.</br>
  These compose files need `.env` file with the same env variables for the DEFAULT_NETWORK
  as the caddy has.</br>
  Note the lack of published/mapped ports in the compose.
  Since the containers are all on the same bridge network, they can access each other on any port.
  Exposed ports are basicly [just documentation.](https://maximorlov.com/exposing-a-port-in-docker-what-does-it-do/)</br>

  *extra info:*</br>
  To know which ports containers have exposed - `docker ps` or `docker inspect`

    `whoami-compose.yml`
    ```
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
    ```
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

- **Run it all**</br>
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

  There's also other possible issues, like bad port forwarding towards docker host,
  or trying to access domain from local network without
  [dealing with it](https://superuser.com/questions/139123/why-cant-i-access-my-own-web-server-from-my-local-network),
  for example by adding in to the `hosts` file ip and subdomain.domain
  of the docker host - `192.168.1.200 a.blabla.org`

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
      reverse_proxy server-blue:8080
  }
  ```

  But there are some cases that want something extra,
  as shown in following examples.


  **Backend communication**</br>
  Some containers might be set to communicate only through https 443 port.
  But since they are behind proxy and likely not fully configured,
  their certificates wont be singed, wont be trusted.

  Caddies sub-directive `transport` sets how to communicate with the backend.
  Setting port to 443 or declaring `tls` makes it use https.
  Setting `tls_insecure_skip_verify` makes it trust whatever certificate
  is coming from the backend.

  ```
  nextcloud.{$MY_DOMAIN} {
      reverse_proxy {
          to nextcloud:443
          transport http {
              tls
              tls_insecure_skip_verify
          }
      }
  }
  ```

  **HSTS and redirects**</br>
  Running Nextcloud behind any proxy likely shows few warning in its status page.
  It requires some redirects for service discovery to work and would really
  like if [HSTS](https://www.youtube.com/watch?v=kYhMnw4aJTw) would be set</br> 
  Like so:

  ```
  nextcloud.{$MY_DOMAIN} {
      reverse_proxy nextcloud:80
      header Strict-Transport-Security max-age=31536000;
      redir /.well-known/carddav /remote.php/carddav 301
      redir /.well-known/caldav /remote.php/caldav 301
  }
  ```

  **gzip and headers**</br>
  This example is with Bitwarden password manager, which comes with its reverse proxy
  [recommendations](https://github.com/dani-garcia/bitwarden_rs/wiki/Proxy-examples).
  
  `encode gzip` enables compression.
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

  **logging**</br>
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

  Caddy [needs](https://github.com/caddyserver/tls.dns) to be compiled with dns module imported... so this is untested.
  But I assume the configuration would go something like this:

  - **DNS record**</br>
    Using cloudflare.</br>
    Make sure A-Type record pointing test.blabla.org to the correct public IP exists,
    and that it is all properly forwarded from there to the docker host.

  - **Caddyfile**</br>

    `Caddyfile`
    ```
    {
        # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
    }

    test.{$MY_DOMAIN} {
        reverse_proxy whoami:80
        tls {
          dns cloudflare
        }
    }
    ```

  - **.env file**

    `.env`
    ```
    # GENERAL
    MY_DOMAIN=blabla.org
    DEFAULT_NETWORK=caddy_net
    TZ=Europe/Prague

    # CLOUDFLARE    
    CLOUDFLARE_EMAIL=bastard@whatever.org
    CLOUDFLARE_API_KEY=global-api-key-goes-here
    ```


# Caddy basicauth

  [Official documentation.](https://caddyserver.com/docs/caddyfile/directives/basicauth)</br>
  If username/password check before accessing a service is required. 
  
  - **Add basicauth section to the Caddyfile**</br>

    Password is [bcrypt](https://www.devglan.com/online-tools/bcrypt-hash-generator) encrypted
    and then [base64](https://www.base64encode.org/) salted.</br>
    In this case username and password are *bastard* / *bastard*

    `Caddyfile`
    ```
    {
        # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
    }

    b.{$MY_DOMAIN} {
        reverse_proxy whoami:80
        basicauth {
          bastard JDJhJDA0JDVkeTFJa1VjS3pHU3VHQ2ZSZ0pGMU9FeWdNcUd0Wk9RdWdzSzdXUXNhWFFLWW5pYkxXVEU2
        }
    }
    ```
