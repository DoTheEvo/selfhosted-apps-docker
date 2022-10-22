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
For web gui frontend it uses lighttpd web server, PHP/Phalcon framework
and custom services built in Python.

Can be installed on a physical server or in a virtual machine.

<details>
<summary><h1>VMware ESXi</h1></summary>

This setup is running on the free version of ESXi 7.0 U3<br>

#### Network setup

Two physical network cards - NICs

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

Afte the initial setup, install plugin `os-vmware`<br>
System > Firmware > Plugins

</details>

<details>
<summary><h1>First login and basic setup</h1></summary>

* at the LAN ip login
* click through wizzard, use 8.8.8.8 and 1.1.1.1 for DNS
* 

</details>


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

now from local LAN side one can access web gui with https://fw.example.com
and its an encrypted communication between the browser and the firewall

</details>

<details>
<summary><h1>Geoblock</h1></summary>

Lock out the entire world from your network, except for your own country.
Great security benefits, but if you dont use dns challange you might have issues
with https certificates renewal and other stuff thats initiated connection
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
