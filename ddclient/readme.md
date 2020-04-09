# ddclient

###### guide by example

### purpose

Automatic DNS entries update. Useful if no static IP from ISP.

* [Github](https://github.com/ddclient/ddclient)

### files and directory structure

  ```
  /etc
  └── ddclient
      └── 🗋 ddclient.conf
  ```

### configuration

Example is for cloudflare managed DNS.

  `ddclient.conf`

  ```
  daemon=300
  syslog=yes
  mail=root
  mail-failure=root
  pid=/var/run/ddclient.pid
  ssl=yes

  use=web, web=checkip.dyndns.org/, web-skip='IP Address'
  wildcard=yes

  ##
  ## CloudFlare (www.cloudflare.com)
  ##
  protocol=cloudflare,        \
  zone=blabla.org,              \
  ttl=1,                      \
  login=bastard.blabla@gmail.com, \
  password=global-api-key-goes-here \
  blabla.org,*.blabla.org

  ##
  protocol=cloudflare,        \
  zone=blabla.tech,              \
  ttl=1,                      \
  login=bastard.blabla@gmail.com, \
  password=global-api-key-goes-here \
  blabla.tech,*.blabla.tech
  ```

### reverse proxy

  no web interface

### update

  during host linux package update
