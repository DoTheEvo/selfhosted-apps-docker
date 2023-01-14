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
<summary><h1>VMware ESXi</h1></summary>

This setup is running on the free version of ESXi 7.0 U3<br>

#### Network setup

Two physical network cards - NICs

![esxi-network](https://i.imgur.com/xvjyF3a.gif)

* the default `vSwitch0` will be used for LAN side
* create new virtual switch - `vSwitch1-WAN`
* create new port group - `WAN Network`, assign to it `vSwitch1-WAN`

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
<summary><h1>First login and basic setup</h1></summary>

* at the LAN ip login
* click through wizzard, use 8.8.8.8 and 1.1.1.1 for DNS
* 

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
Many consider NAT reflection a hack that should not be used or even allowed.<br>
That the correct way is split DNS, where you maintain DNS records so that
`a.example.com` points directly to some local 192.168.0.12 IP address.<br>
Reason being that since DNS records are cached, this way machines on LAN,
that use hostname to access each other, are not hitting the firewall with
every traffic that goes between two machines on LAN side.
But IMO in small scale selfhosted setup its perfectly fine and it requires
far less management.

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
Great security benefits, but if you dont use dns challenge you might have issues
with https certificates renewal and other stuff that initiates connection
from the outside.

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

### current live view of connections

Firewall: Log Files: Live View<br>
The filter and autorefresh on/off allow to investigate traffic

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
* 


</details>

---
---

### Extra info and encountered issues

* Health check - `System: Firmware` Run an audit button, Health
* zenarmor that was disabled caused<br>
  opnsense and PHP Startup: Unable to load dynamic library 'mongodb.so' 
