# Docker basics and troubleshooting

###### guide-by-example

![logo](https://i.imgur.com/GrWPooR.png)


# Purpose

For me to wrap head around some shit.
Notes for troubleshooting.

What was at one time tested and should 100% work.

# docker-compose

`docker-compose.yml`
```yml
services:

  whoami:
    image: "containous/whoami"
    container_name: "whoami"
    hostname: "whoami"
    ports:
      - "80:80"
```



# Scheduling and cron issues

The default docker-compose deployment uses cron container.<br>
Problem is it does not work, so Ofelia is used.<br>
[Here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/ofelia)
is guide how to set it up.

Bellow is Ofelia's config file for discovery and ping check of live hosts.

`config.ini`
```ini
[job-exec "phpipam ping"]
schedule = @every 10m
container = phpipam-web
command = /usr/bin/php /phpipam/functions/scripts/pingCheck.php

[job-exec "phpipam discovery"]
schedule = @every 25m
container = phpipam-web
command = /usr/bin/php /phpipam/functions/scripts/discoveryCheck.php
```

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
ipam.{$MY_DOMAIN} {
    reverse_proxy phpipam-web:80
}
```

# First run

![logo](https://i.imgur.com/W7YhwqK.jpg)


* New phpipam installation
* Automatic database installation
* MySQL username: root
* MySQL password: my_secret_mysql_root_pass

# Update

[Watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower)
updates the image automatically.

Manual image update:

- `docker-compose pull`<br>
- `docker-compose up -d`<br>
- `docker image prune`

# Backup and restore

#### Backup

Using [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the entire directory.
  
#### Restore

* down the homer container `docker-compose down`<br>
* delete the entire homer directory<br>
* from the backup copy back the homer directory<br>
* start the container `docker-compose up -d`
