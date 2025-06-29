# OPNsense

###### guide-by-example

![logo](https://i.imgur.com/3ROLmaz.png)

# Purpose

Firewall, router, dhcp server, recursive DNS, VPN, traffic monitoring.

* [Official site](https://opnsense.org/)
* [GitHub](https://github.com/opnsense)
* [Subreddits](https://www.reddit.com/r/opNsenseFirewall+opnsense/)

Opensource.<br>
Backend is FreeBSD with its packet filter `pf` and `configd`
for managing daemons, services and templates.<br>
For web gui it uses lighttpd web server, PHP/Phalcon framework
and custom services built in Python.

Can be installed on a physical server or in a virtual machine.

<details>
<summary><h1>Install in various hypervisors</h1></summary>


<details>
<summary><h1>VMware ESXi</h1></summary>

This setup is running on the free version of ESXi 7.0 U3<br>

#### Network setup

Two physical network cards - NICs

![esxi-network](https://i.imgur.com/xvjyF3a.gif)

* the default `vSwitch0` will be used for LAN side
* create new virtual switch - `vSwitch1-WAN`
* create new port group - `WAN Network`, assign to it `vSwitch1-WAN`

If plannig VLANs port groups need them assigned, trunk needs vlan 4095 set.

#### Virtual machine creation

* Guest OS family - Other
* Guest OS version - FreeBSD 13 or later versions (64-bit)
* CPU - 2 cores
* RAM - 2GB, for basic functionality, later can assign more 
* SCSI Controller 0 - LSI Logic SAS
* VM Options > Boot Options > Firmware - EFI

Afterwards, edit the VM, add network adapter connected to `WAN Network`

[Download](https://opnsense.org/download/) the latest opnsense - amd64, dvd,
extract iso, upload to ESXi datastore,
mount it in to the VMs dvd, check connect on boot

#### OPNsense installation in VM

Disconnect your current router and plug stuff in to the ESXi host.

* let it boot up
* login `root/opnsense`
* set interfaces, in ESXi VM overview you can see networks and MAC addresses 
* set IPs, wan is usually left alone with dhcp,<br>
  static ip for LAN and enable dhcp server running and give it range
* afterwards you should be able to access web gui
* log out
* log in as `installer/opnsense`
* click through installation leaving stuff at default except for password
* done

After the initial setup, install plugin `os-vmware`<br>
System > Firmware > Plugins

</details>

---
---

<details>
<summary><h1>Hyper-V</h1></summary>

Tested in windows 11 pro, v10.0.22621<br>

#### Network setup

Two physical network cards - NICs

![esxi-network](https://i.imgur.com/WnVQiZC.gif)

* the Default Switch will not be used.
* create new virtual switch - `WAN`<br>
  `external`, unchecked - *Allow management operating system to share this network adapter*<br>
  set correct physical NIC
* create new virtual switch - `LAN`<br>
  `external`, set correct physical NIC<br>

A cable with a live device at the end must be connected to LAN NIC 
for that LAN part of setup to start working.

#### Virtual machine creation

[Download](https://opnsense.org/download/) the latest opnsense - amd64, dvd,
extract 

* generation 2
* firmware > security > turn off secure boot
* SCSI Controller add DVD and mount opnsense iso
* 2 cores, 2GB ram, for basic functionality, later can assign more 
* add two virtual NICs, assign WAN and LAN virtual switches
* firmware boot order change
* turn off automatic checkpoints
* automatic stop action - shutdown

Start the VM


#### OPNsense installation in VM

Disconnect your current router and plug stuff in to the ESXi host.

* let it boot up
* login `installer/opnsense`
* click through the install process
  * UFS
  * disk
  * 8GB for swap
  * keep default password for now
  * set the interfaces, in hyperv you can check mac addresses
* set IPs, wan is usually left alone with dhcp,<br>
  static ip for LAN and enable dhcp server running and give it range
* afterwards you should be able to access web gui
* log out
* done

No need to install some hyperv plugin after the installation,
its included automaticly.

**In case of disconnect of LAN side cable/switch, the hyperv host also loses connection**<br>
Even if one might think it should work - WAN side is there, firewall is running,
but it's the way hyperv external vswitches work. The physical NIC must be alive.<br>
If the switch would be `internal` then it would be entirely virtual and independent
of physical NIC state, but in host windows network connections,
one cant bridge internal and external, switches nor NICs.<br>
One way to solve this mild annoyance is to have external WAN, internal LAN1,
and external LAN2. LAN1 and LAN2 would be
[bridged in opnsense](https://docs.opnsense.org/manual/how-tos/lan_bridge.html).
But seems this is rather cpu intensive and not recommended.<br>
So I guess its living with this.

</details>

---
pkg install xe-guest-utilities
echo 'xenguest_enable="YES"' >> /etc/rc.conf.local
ln -s /usr/local/etc/rc.d/xenguest /usr/local/etc/rc.d/xenguest.sh
service xenguest start


---

<details>
<summary><h1>XCP-ng</h1></summary>

[Official xcp instructions.](https://docs.xcp-ng.org/guides/pfsense/)<br>
Read the link above, dont skip it, might be newer info there!


#### Network setup

There are two ways to do the trunk port, **the easier one** will be used here,
the one where opnsense is not doing anything with vlans as xcpng deals 
with them and each vlan is a separate network in xcpng and a separate
interface in opnsense. Limitation is that you should **not go above 7**.<br>
So again, **no touching vlans in opnsense**.

* PIF - physical NIC
* VIF - virtual NIC
* Network in XO - basicly a virtual switch to which stuff connects

The network setup is done under **the pool** section, not host or a VM.<br>
Decide on WAN and LAN interfaces for opnsense,
any additional vlan you want, create a new networks with that VLAN tag.

* New > Network > your-pool
* Type - leave both settings off - bonded and private
* Interface - pick physical interface if using it or if doing VLANs.
  Leave empty if creating a new virtual one to which only VMs will connect
* Name it
* MTU leave default 1500
* VLAN tag if desired
* Create network

You are done when you have your LAN, WAN and VLANs ready.

#### Virtual machine creation

[Download](https://opnsense.org/download/) the latest opnsense - amd64, **dvd**,
extract iso.

* New > VM > your-pool
* Template - Other install media
* name; description; vcpu; ram; topology; iso
* Interfaces - create new interafaces for LAN, WAN, and VLANs<br>
* add virtual disk
* button - Show advanced settings
  * Boot firmware - **uefi**
* Create

#### Disable TX Checksum Offload

Head to the "Network" tab of your opnsense VM now<br>
advanced settings (click the blue gear icon) for each adapter<br>
disable TX checksumming.<br>
Restart the VM.

Note the warning in the official docs, no need to do this in opnsense
or anywhere else, just on the xcpng virtual interfaces of that VM and only TX.

#### Updates

After the fresh install run the updates.

#### Xen guest additions

`System: Firmware : Plugins`<br>
Install `os-xen` plugin. Restart the opnsense VM.

If all goes well in xcpng you see that the agent is detected for the VM.

<details>
<summary><h5>Manual installation</h5></summary>

In a case the plugin would not work.

* enable ssh on the opnsense<br>
  `System: Settings: Administration` > Secure Shell
* ssh in 
* `pkg install xe-guest-utilities`
* `echo 'xenguest_enable="YES"' >> /etc/rc.conf.local`
* `ln -s /usr/local/etc/rc.d/xenguest /usr/local/etc/rc.d/xenguest.sh`
* `service xenguest start`

The package will have some notice in the webGUI,
but that is because it was installed manually using pkg.

---
---

</details>

---
---

</details>

---
---

</details>

# First login and basics

* click through wizzard, keep mostly defaults
  * hostname, DNS use 8.8.8.8 and/or 1.1.1.1
  * timezone and ntp server
  * WAN - DHCP , defaults
  * LAN - set network and mask, I prefer 10.0.X.1
  * root password
* Update; Restart

Afterwards you have a working router/firewall with WAN side and LAN side,
Unbound for DNS and ISC or KEA for DHCP.<br>
The default NAT and firewall enforces basic stuff.

# Users

Good practice is to create a new administrator user and disable the root account.

* Add a new user - `System: Access: Users`
* username ideally named sometething not common; password
* Login shell - `/bin/sh`
* Group membership - `admins`
* Privileges - `All pages`

If the user should also be able to SSH in and sudo

* `System: Settings: Administration`
* Secure Shell Server - Enable
* Authentication Method -  Permit password login
* Sudo - `Ask password`; `wheel, admins`

Now disable the login for the root.
Be aware it will also disable console login not just webGUI.

* `System: Access: Users`
* root; edit; disable; save

# DHCP

[Official docs](https://docs.opnsense.org/manual/dnsmasq.html)

2022 Internet Systems Consortium stopped development of ISC DHCPD that was
widely used in favor of working on Kea DHCP.<br>
Opnsense needed to make a decision what to use next as the default,
Kea or dnsmasq and decided to use dnsmasq.<br>
But since it's not yet the default, here are the steps.

The simple dnsmasq setup.


* Make sure other DHCP services are disabled<br>
  `Lobby: Dashboard` section Services should not list any dhcp
* configure dnsmasq<br>
  `Services: Dnsmasq DNS & DHCP`
* General tab
    * Enable - check
    * Interfaces - select your LAN and VLANs interfaces on which dhcp should run
    * DNS Listening Port - `0` this disables the DNS functionality.
    * DHCP authoritative - check
    * DHCP register firewall rules - check
* DHCP ranges tab
  * add a new range<br>
  * select the interface
  * set the `Start address` and the `End address`
  * Lease time, I like 10 days - `864000` for small number of devices networks


With dnsmasq theres also an option pass leaseas to unbound DNS,
[here's the setup](https://docs.opnsense.org/manual/dnsmasq.html#configuration-examples)

<details>
<summary><h1>VLANs</h1></summary>

* [general info on vlans](https://github.com/DoTheEvo/selfhosted-apps-docker/blob/master/_knowledge-base/vlans.md)
* [opnsense video](https://youtu.be/LMJeIUDlrHo)
* [pfsense video but applicable](https://youtu.be/SsaGeXx2qh0)

The basics

Will be creating vlan for security cameras on the network.<br>
vlan tag will be `30`, the subnest will be `10.30.30.0/24`

* Create a VLAN - `Interfaces: Devices: VLAN`
  * Device - leave empty, it will be generated, custom names require to follow a scheme
  * Parent - physical interface it is associated with
  * VLAN tag - the vlan tag, usually 20, 30, 40,...
  * VLAN priority - default
  * Description - purpose, for example cameras, or guest wifi
  * apply
* Assign the VLAN to a new interafece - `Interfaces: Assignments`<br>
  It should be listed where you just put in description and add it
* Enable and configure the new interface - `Interfaces: [vlan30cameras]`
  * enable it
  * IPv4 Configuration Type - Static IPv4
  * IPv4 address, let's say `10.30.30.1/24`
  * apply
* Enable DHCP for this new VLAN - `Services: ISC DHCPv4: [vlan30cameras]`
  * Enable it
  * Range - `10.30.30.50` to `10.30.30.200`
  * Save
* in lobby dashboard Services - `KEA DHCPv4 server` should be running

<summary><h5>If running opnsense as a virtual machine.</h5></summary>

### xcpng

If running opnsense as a VM under xcpng then vlans are presented as regular
interfaces. Xcpng is doing tagging and untagging, for opnsense they are just NICs.

### ESXI

![esxi](https://i.imgur.com/uvpF8KC.png)

For VLAN aware devices on the network to get through

* Edit the port group with the opnsense VM LAN interface
  and add VLAN ID = `4095`<br>
  This will allow all VLANs to get through

For a virtual machine on that ESXI host should be on that VLAN

* Add new port group, to the virtual switch that opnsense uses for LAN<br>
  Name = `vlan20`; VLAN ID = `20`

Now you can edit a VM or create new one, set its Network Adapter to `vlan20`
and it should get ip address from the vlan 20 dhcp pool. 

This is a good test if stuff works as it should before diving in to configuration
of VLANs on switches.


</details>

---
---


<details>
<summary><h1>DNS - Unbound</h1></summary>

Build in DNS server, enabled by default, listening at port 53

Services: Unbound DNS: General

</details>

---
---

<details>
<summary><h1>Web GUI access from WAN side</h1></summary>

For example in cases where the only thing under protection of opnsense
are some VMs on a hypervisor, but managment is easier done from the host.<br>
Or if the risk is acceptabale,hoping random port, long password for a non-root user,
and maybe some IP restrictios will be enough.

- `pfctl -d` disables firewall and allows immediate web gui access on the WAN IP.<br>
  A restart of opnsense will always re-enable packet filtering
- Disable `Block private networks` in `Interfaces: [WAN]`.
- Set up a firewall rule that allows WAN traffic in `Firewall: Rules: WAN`<br>
  Add new rule; everything is left default except the `Destination`
  is set to `This Firewall`.<br>
  Can also enable `Log packets that are handled by this rule` if use of this rule
  should be visible in `Firewall: Log Files: Live View`.
- Turn on `Disable reply-to` in `Firewall: Settings: Advanced`,<br>
  otherwise connections made from the same network will not get through.<br>
  Some [read on this.](https://forum.opnsense.org/index.php?topic=15900.0)
- Reboot.<br>
  Afterwards opnsense should be accessible on WAN IP, without the need for `pfctl -d`.

For some harderining of security.

* Change the default web gui port in `System: Settings: Administration`.<br>
  From `443` to something random in range of 1024-65k, something like 32179.<br>
  Afterwards to access opnsense the port must be added to the url `<IP>:32179`
* Turn off `HTTP Redirect` in `System: Settings: Administration`.<br>
  This only allows https encrypted communication.
* Create a new user; add to administrators; disable `root` user
  in `System: Access: Users`.<br>
  Brute forcing username and password is more difficult than brute force
  password for a known user `root`.
* Adjust the firewall WAN rule to be more restrictive.<br>
  Instead of `source` being `any`, setting a specific single machine IP.<br>
  Either right in the rule with `Single host or Network` and `192.168.1.200/32`,<br>
  or setting up an alias in `Firewall: Aliases`, setting IP in the `Content` field

</details>

---
---

<details>
<summary><h1>Port fowarding and NAT reflection(hairpin/loopback)</h1></summary>

[source](https://forum.opnsense.org/index.php?topic=8783.0)

### NAT reflection

When you write `a.example.com` in to your browser,
you are asking a DNS server for an IP address.
When selfhosting that `a.example.com` it will give you your own public IP,
and most consumer routers don't allow this loopback, where your requests
should go out and then right back.<br>
So a solution for above-consumer-level routers/firewalls is to just have 
checkboxes about NAT reflection, also called hairpin NAT or a NAT loopback.

`Firewall: Settings: Advanced`
- Reflection for port forwards: `Enabled`
- Reflection for 1:1: `Disabled`
- Automatic outbound NAT for Reflection: `Enabled`

*extra info:*<br>
Many consider NAT reflection to be a hack that should not be used.<br>
That the correct way is split DNS, where you maintain separate DNS records for
LAN side so that `a.example.com` points directly to some local ip.
Reason being that this way machines on LAN side that use FQDN(a.example.com)
to access other machine on LAN are not hitting the firewall with traffic
that goes between them.
But IMO in small scale selfhosted setup its perfectly fine
and it requires far less management.

### Port Forwarding:

a host with IP 192.168.1.200, with port 3100 open TCP<br>
want to port forward from the outside 3200 to 3100

- set up Aliases in `Firewall: Aliases`<br>
  - name: A short friendly name for the IP address you're aliasing. I'll call it "media-server"
  - type: Host(s)
  - Aliases: Input 192.168.1.200

- register the portforwarding in `Firewall: NAT: Port Forward`<br>
  - Interface: `WAN`
  - TCP/IP Version: `IPv4`
  - Protocol: `TCP`
  - Under `Source > Advanced`:<br>
    - Source / Invert: `Unchecked`
    - Source: `Any`
    - Source Port Range: `any to any`
  - Destination / Invert: `Unchecked`
  - Destination: `WAN address`
  - Destination Port range: `(other) 3200 to (other) 3200`
  - Redirect target IP: `Alias "media-server"`
  - Redirect target Port: `(other) 3100`

</details>

---
---


<details>
<summary><h1>Switch to https</h1></summary>

Not really needed. More like an exercise.
But hey, its extra protection from someone snooping
who is already on the LAN side I guess.

### on cloudflare

* create dns record `fw.example.com`
* get user ID - its in the url when you are on cloudflare dashboard, looks like 0122db3h3824893914169c9c4f919747f
* in My Profile >  Api Tokens > get Global API Key
* in My Profile >  Api Tokens > create token that looks [like this](https://i.imgur.com/pRelkUu.png)
    * zone/zone/read
    * zone/dns/edit
    * include all zones

### in opnsense acme plugin

* download acme plugin
* Services: ACME Client: Accounts - create account with your email
  where notifications about certs can go
* Services: ACME Client: Challenge Types - create new dns challange with info
  you gathered from cloudflare,
  looks something [like this](https://i.imgur.com/bYZ6pTj.png)
* Services: ACME Client: Certificates - create new certificate,
  stuff is just picked from the drop down menus,
  [looks like this](https://i.imgur.com/MC1kBCV.png)
* now check logs if request went through on its own, or just click small icon
  to force renew the certificate, in logs in matter of a minute
  there should be some either success or fail

### in opnsense Services: Unbound DNS: General

* add an override - so that the fw.example.com points to your local ip
  instead of going out, [looks like this](https://i.imgur.com/vqT9t3Y.png)

### in opnsense System: Settings: Administration

* Alternate Hostnames - add your fw.example.com
* SSL Certificate -  pick from dropdown menu your certificate
* apply changes
* switch radio buttons at the top from http to https if its not already.<br>
  The previous steps should be done as opnsense will want to reload gui

### automatic renewal

* `Services: ACME Client: Settings` - click tab - `Update Schedule`<br>
  opens `System: Settings: Cron` where renewal schedule in cron format is set<br>
* everything is left default, only changing hours=`3` and months=`*/2`<br>
  this sets schedule to every other month at 3 after midnight.
* cant tell yet if its working or not, got to wait few months and check

now from local LAN side one can access web gui with https://fw.example.com
and its an encrypted communication between the browser and the firewall

</details>

---
---

<details>
<summary><h1>Geoblock</h1></summary>

Lock out the entire world from your network, except for your own country.
Great security benefits, but if you dont use
[dns challenge](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2#caddy-dns-challenge)
you might have issues with https certificates renewal and other stuff
that initiates connection from the outside.

Following [the official documentation](https://docs.opnsense.org/manual/how-tos/maxmind_geo_ip.html)

### on maxmind.com

* register account on [maxmind.com](https://www.maxmind.com/en/geolite2/signup),
  this will give access to info which IP ranges belong to which country
* in the freshly created maxmind account generate new license
* in this url replace `My_License_key` with your actual license key<br>
  `https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=My_License_key&suffix=zip`
* paste it in browser, if its working it should download zip file with the IP info 

### in opnsense

* Firewall: Aliases: GeoIP tab - paste the url, click apply
* switch to Aliases tab, create new geoip alias and select your own country<br>
  [something like this](https://i.imgur.com/vu2slRd.png)
* Firewall: Rules: WAN - create new rule<br>
  block; source invert; source geoip alias we created;
  enable log packets that are handled by this rule; add description<br>
  [something like this](https://i.imgur.com/qi7sL9J.png)

Observe it in action in Firewall: Log Files: Live View   

If you host anything with a website you can test if its working by using
opera build in vpn, or by using some
[online web site testers](https://www.webpagetest.org/).
Assuming you are not in the country from which these run their test.
 
</details>

---
---


<details>
<summary><h1>Monitoring</h1></summary>

### ARP table

Interfaces: Diagnostics: ARP Table<br>

### live view of connections

Firewall: Log Files: Live View<br>
Great tool to investigate settings and behavior with it's filter
and autorefresh on/off and up to 20k last entries.<br>
Must **enable logging** for a rule to be visible there.

* checking out a specific firewall rule latest use<br>
  `label` `contains` `some string from the rules description`<br>
* targeting specific ip on the LAN, for example docker host<br>
  `dst` `is` `192.168.19.200`<br> 
  or ip address of a reverse proxy in docker, for me it was `10.36.44.8`
* or specific port, like for minecraft
  port is 25565
* controlling for direction and understanding the concept
  - 🡪 IN means in to a firewall, 🡨 OUT means out of a firewall
  - the interfaces WAN/LAN, give the meaning to these IN/OUT directions
  - IN on LAN interface means traffic is leaving LAN and heading out through firewall
  - IN on WAN interface means traffic is coming in to 
  - OUT on LAN means its leaving firewall and heading to LAN 
  - OUT on WAN means its leaving firewall and heading to the WAN side

### checking traffic from a local device

* `Firewall: Rules: LAN`
  * enable logging for the `Default allow LAN to any rule`
* `Firewall: Log Files: Live View`
  * set interface to lan
  * set source for the desired ip 

</details>

---
---

<details>
<summary><h1>Plugins</h1></summary>

[zenarmor](https://www.zenarmor.com/docs/guides/best-practices-for-zenarmor-deployment)

* os-vnstat to have some general idea about traffic

</details>

---
---

<details>
<summary><h1>Grafana dashboard monitoring</h1></summary>

![dashboard](https://i.imgur.com/SFd8773.png)

[bsmithio/OPNsense-Dashboard](https://github.com/bsmithio/OPNsense-Dashboard)
seems like amazingly well done thing that everyone would want.. if it was easy.

Annoying thing is that I invested time and effort in to monitoring my
[caddy reverse proxy](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2#monitoring)
and learning prometheus, loki, promtail,... and literaly the moment I was done
I started to think about why not do that for firewall instead of reverse proxy
and so I found now bsmithio project that uses completely different stack - 
mongo, elasticsearch, graylog, influxdb.

Well, [the documentation](https://github.com/bsmithio/OPNsense-Dashboard/blob/master/configure.md)
seems to be excelent so lets try this shit out.

Though still I learn best by step by step documenting shit as I try it,
and make adjustments to my prefernce... so lets try again here.

```
services:

  mongodb:
    image: mongo:6.0.4
    container_name: opns-mongo
    hostname: opns-mongo
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./mongodb_data:/data/db

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch-oss:7.10.2
    container_name: opns-elasticsearch
    hostname: opns-elasticsearch
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./elasticsearch_data:/usr/share/elasticsearch/data

  graylog:
    image: graylog/graylog:5.0.2
    container_name: opns-graylog
    hostname: opns-graylog
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./graylog_data:/usr/share/graylog/data
    depends_on:
      - mongodb
      - elasticsearch
    ports:
      - "9000:9000"      # Graylog web interface and REST API
      - "1514:1514/udp"  # Syslog UDP
      # - "1514:1514"      # Syslog TCP Optional
  
  influxdb:
    image: influxdb:2.6.1
    container_name: opns-influxdb
    hostname: opns-influxdb
    restart: unless-stopped
    env_file: .env
    ports:
      - "8086:8086"
    volumes:
      - ./influxdb_data:/var/lib/influxdb2

  grafana:
    image: grafana/grafana:9.4.3
    container_name: opns-grafana
    hostname: opns-grafana
    user: root
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./grafana_data:/var/lib/grafana
    depends_on:
      - influxdb
    ports:
      - '3003:3000'

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true
```

```
# GENERAL
DOCKER_MY_NETWORK=caddy_net
TZ=Europe/Bratislava

# ELASTICSEARCH
http.host=0.0.0.0
transport.host=localhost
network.host=0.0.0.0
ES_JAVA_OPTS=-Xms512m -Xmx512m

# GRAYLOG
ROOT_TIMEZONE=Europe/Bratislava
GRAYLOG_TIMEZONE=Europe/Bratislava
# CHANGE ME (must be at least 16 characters)! This is not your password, this is meant for salting the password below.
GRAYLOG_PASSWORD_SECRET=ZicwMzt3NTE4ZzIwM
# Username is "admin"
# Password is "admin", change this to your own hashed password. 'echo -n "password" | sha256sum' 
GRAYLOG_ROOT_PASSWORD_SHA2=8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918
GRAYLOG_HTTP_EXTERNAL_URI=http://127.0.0.1:9000/

# GRAFANA
GF_SECURITY_ADMIN_USER=opnsense
GF_SECURITY_ADMIN_PASSWORD=opnsense
# GF_INSTALL_PLUGINS=grafana-worldmap-panel
```

</details>

---
---

### Extra info and encountered issues

* Health check - `System: Firmware` Run an audit button, Health
* got error notice:<br>
  *opnsense and PHP Startup: Unable to load dynamic library 'mongodb.so'*<br>
  seems its some remnant of zenarmor.
  [Heres](https://forum.opnsense.org/index.php?topic=29721.0) the talk on it.<br>
  `pkg list | grep mongo` to get exact package name.<br>
  `pkg remove php74-pecl-mongodb` to remove the package

 
zenarmor that was disabled caused an error notification<br>
  
links 

* [12 Ways to Secure Access to OPNsense and Your Home Network](https://homenetworkguy.com/how-to/ways-to-secure-access-to-opnsense-and-your-home-network/)
* [Beginner's Guide to Set Up a Home Network Using OPNsense](https://homenetworkguy.com/how-to/beginners-guide-to-set-up-home-network-using-opnsense/)
* [M920q Router](https://github.com/ianhaddock/m920q-router)
* [redirect-all-dns-requests-to-local-dns-resolver](https://homenetworkguy.com/how-to/redirect-all-dns-requests-to-local-dns-resolver/)
