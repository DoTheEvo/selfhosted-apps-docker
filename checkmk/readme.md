# checkmk

###### guide-by-example

![logo](https://i.imgur.com/yMDhlLJ.png)

# Purpose

Monitoring of machines, containers, services, logs, ...

* [Official site](https://checkmk.com/)
* [github](https://github.com/Checkmk/checkmk)

Monitoring in this case means gathering and showing information on how services
or machines or containers are running.
Can be cpu, io, ram, disk use, network throughput, latency,...
can be number of http requests, errors, results of backups...

# Overview

[Good youtube overview.](https://www.youtube.com/watch?v=7OnhuCsR7jg)

checkmk is a fork of nagios and is mostly written in python.<br>
Interesting fact is that there is no database where data are stored,
RRD files for metrics and plaintext logs for everything else.

Agents are installed on machines that should be monitored,
they expose gathered data at port 6556 for cmk to pull.<br>
SNMP support as well.

![overview](https://i.imgur.com/HB0bLyU.png)

### Editions

[Docs](https://docs.checkmk.com/master/en/intro_setup.html#editions)

* **raw** - 100% open source, unlimited use, some features are missing
  or are harder to set up. For example no push mode from agents.
* **cloud** - full featured with better performing version of the monitoring micro core,
  but with 750 services limit

I am gonna go with cloud for now, as 750 sounds like plenty for my use cases.


# Files and directory structure

```
/home/
 └── ~/
     └── docker/
         └── checkmk/
             ├── 🗁 checkmk_data/
             ├── 🗋 docker-compose.yml
             └── 🗋 .env
```

* `checkmk_data/` - a directory where checkmk_data stores its persistent data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

The two files must be provided.</br>
The directory is created by docker compose on the first run.

# docker-compose

A simple compose.<br>
Of note is use of ram as tmpfs mount into the container
and setting a 1024 limit for max open files by a single process.

*Note* - the port is only `expose`, since theres expectation of use
of a reverse proxy and accessing the services by hostname, not ip and port.

[Docs](https://docs.checkmk.com/latest/en/ports.html) on ports used in cmk.

`docker-compose.yml`
```yml
services:
  checkmk:
    # image: checkmk/check-mk-raw 
    image: checkmk/check-mk-cloud
    container_name: checkmk
    hostname: checkmk
    restart: unless-stopped
    env_file: .env
    ulimits:
      nofile: 1024
    tmpfs:
      - /opt/omd/sites/cmk/tmp:uid=1000,gid=1000
    volumes:
      - ./checkmk_data:/omd/sites
      - /etc/localtime:/etc/localtime:ro
    expose:
      - "5000"      # webgui
    ports:
      - 8000:8000   # agents who push

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

# CMK
CMK_SITE_ID=dom
CMK_PASSWORD=WUx666yd0qCWh
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

## Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```php
cmk.{$MY_DOMAIN} {
  reverse_proxy checkmk:5000
}
```

# First run 

![login](https://i.imgur.com/pDCvn4D.png)

Visit `cmk.example.com` or whatever you set in reverse proxy.<br>
Password for user `cmkadmin` is set the `.env` file.

Usual security recommendation is to create a new user
and disable the default admin account.

# Agents

![login](https://i.imgur.com/vC5peFG.png)

## Installation Windows Machine

[Documentation](https://docs.checkmk.com/latest/en/agent_windows.html)

* Note the hostname and the ip address of the machine.
* Agent installation msi file is available at <br>
 `https://cmk.example.com/<site-name>/check_mk/agents/`<br>
  or webgui - Setup > Agents > Windows, Linux, Solaris, AIX > Windows - MSI<br>
  downloads an msi, install.
* some win servers by default block ping by their firewall, allow ping through<br>
  `wf.msc` - Inbound Rules - enable "File and Printer Sharing (Echo Request - ICMPv4-In)"
* CMK Web GUI > Setup > Hosts > Add host

  * Host name - `<hostname>` - should be all thats needed
  * IP address family - ipv4 only
  * IPv4 address - `<ip address>`

  Green button - `Save & run service directory`<br>
  After a while list of services should be listed<br>
  Top left green check mark - `Accept all`<br>
  Yellow exclamation mark top right corner - to review changes<br>
  Left top green button - `Activate on selected sites`

#### Agent registration - TLS

Will need password for user - `agent_registration`<br>

  * Setup > Users > agent_registration - edit - blue pencil left
  * green dice - randomizes password - make the note of the new password
  * apply changes - yellow exclamation mark

on the machine where the agent is installed

* cmd as administrator, not powershell
* `cd "C:\Program Files (x86)\checkmk\service\"`
* `cmk-agent-ctl.exe register --hostname WIN-2022 --server cmk.example.com --site dom --user agent_registration --password "TJUE@ILTQFEUFQCT@ADS"`
* DO MAKE SURE YOU USE THE CORRECT **HOSTNAME**<br>
  I spent quite a while troubleshooting when I registered 3rd machine with hostname 
  of the second machine that was already registered.

#### troubleshooting

* Setup > Hosts > `<Host>` > Save & run connection tests
* `cmk-agent-ctl status` - run on the host 
* `echo | nc 10.0.19.194 6556` - executed on the server, hosts ip is used<br>
  before TLS it should reply with data, afterwards its `162%`
* Monitor > Overview > Host search > 3 lines icon next to hostname > Download agent output

## Installation Linux Machine

might be in repos, if not path to cmk instance has agents and plugins<br>
`https://cmk.example.com/<site-name>/check_mk/agents/`<br>

`wget https://cmk.example.com/dom/check_mk/agents/check-mk-agent_2.3.0p6-1_all.deb`
`sudo dpkg -i check-mk-agent_2.3.0p6-1_all.deb`

docker plugin

`wget https://cmk.example.com/dom/check_mk/agents/plugins/mk_docker.py`<br>
`sudo install -m 0755 mk_docker.py /usr/lib/check_mk_agent/plugins`

#### TLS

get password for user - `agent_registration`

`sudo cmk-agent-ctl register --hostname debianu --server cmk.example.com --site dom --user agent_registration --password "TJUE@ILTQFEUFQCT@ADS"`

##### troubleshooting

* `sudo cmk-agent-ctl status`
* `ss -tulpn | grep 6556` - checks if the port is binded
* `netstat -ano | grep 6556`
* after reinstall [the agent does not listen on the port](https://forum.checkmk.com/t/checkmk-agent-not-listening-on-6556-after-reinstalling-agent-v2-1-0/34882)<br>
  `sudo cmk-agent-ctl delete-all --enable-insecure-connections`

# SNMP monitoring

Using a mikrotik switch here

* login to mikrotik > IP > SNMP
* button `Communities`
  * disable public
  * Add New
  * Set Name - `snmp_home`
  * Security - `Authorized`
  * Read Access 
  * authentication protocol - `SHA1`
  * Authentication Password  - set some password
* back in SNMP settings 
* enabled - checked
* Trap Community - `snmp_home`
* Trap Version - `3`
* Apply

CMK Web GUI > Setup > Hosts > Add host

* host name - `CRS310`
* IPv4 address - `10.0.19.240`
* Checkmk agent / API integrations - No API integrations, no Checkmk agent
* SNMP - SNMP v2 or v3
* SNMP credentials - Credentials for SNMPv3 with authentication but without privacy (authNoPriv)
* Authentication protocol - `SHA1`
* Security name - `snmp_home`
* Authentication Password - whatever was set
* Save and run service discovery
* apply changes

# Push

# Alerts

# Logs

# Update

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

# Backup and restore

#### Backup

#### Restore

* down the containers `docker-compose down`</br>
* delete the entire monitoring directory</br>
* from the backup copy back the monitoring directory</br>
* start the containers `docker-compose up -d`
