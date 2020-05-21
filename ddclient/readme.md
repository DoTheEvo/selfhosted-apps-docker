# DDclient

###### guide-by-example

# Purpose & Overview

Automatic DNS entries update. 

* [Official site](https://sourceforge.net/p/ddclient/wiki/usage/)
* [Github](https://github.com/ddclient/ddclient)
* [DockerHub](https://hub.docker.com/r/linuxserver/ddclient)

DDclient is a Perl client used to update dynamic DNS records.</br>
Very useful if not having a static IP from the ISP. 
It makes sure that if you reset your router, or have a power outage,
and you get a new public IP assigned, this IP gets automaticly set
in the DNS records for your domains.

This setup runs directly on the host machine.</br>
It works by checking every 10 minutes
[checkip.dyndns.org](http://checkip.dyndns.org/),
and if the IP changed from the previous one, it logs in to the DNS provider and
updates the DNS records. 

# Files and directory structure

```
/etc/
└── ddclient/
    └── ddclient.conf
```              

# Installation

Install ddclient from your linux official repos.

# Configuration

Official ddclient config example
[here](https://github.com/ddclient/ddclient/blob/master/sample-etc_ddclient.conf).

This setup assumes the DNS records are managed on Cloudflare.</br>
Make sure all subdomains in the config have A-records.

`ddclient.conf`

```bash
daemon=600
syslog=yes
mail=root
mail-failure=root
pid=/var/run/ddclient.pid
ssl=yes

use=web, web=checkip.dyndns.org/, web-skip='IP Address'

##
## CloudFlare (www.cloudflare.com)
##
protocol=cloudflare,        \
zone=example.com,              \
ttl=1,                      \
login=bastard@gmail.com, \
password=<global-api-key-goes-here> \
example.com,*.example.com,subdomain.example.com

##
protocol=cloudflare,        \
zone=example.org,              \
ttl=1,                      \
login=bastard@gmail.com, \
password=<global-api-key-goes-here> \
example.org,*.example.org,whatever.example.org
```

# Start the service

`sudo systemctl enable --now ddclient`

# Troubleshooting

If it would timeout on start, check the real location of `ddclient.pid`</br> 
`sudo find / -name ddclient.pid`

If it is correctly set in the `ddclient.conf`.

# Update

During host linux packages update.

# Backup and restore

#### Backup

Using [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the /etc directory which contains the config file.

#### restore

Replace the content of the config file with the one from the backup.
