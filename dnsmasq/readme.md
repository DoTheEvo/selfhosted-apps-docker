# dnsmasq

###### guide-by-example

![logo](https://i.imgur.com/SOa4kRd.png)

# Purpose & Overview

Lightweight DHCP and DNS server.

* [Official site](http://www.thekelleys.org.uk/dnsmasq/doc.html)
* [Arch wiki](https://wiki.archlinux.org/index.php/dnsmasq)

dnsmasq solves the problem of accessing self hosted stuff when you are inside
your network. As asking google's DNS for `example.com` will return your
very own public IP and most routers/firewalls wont allow this loopback,
where your requests should go out and then right back.</br>
Usual quick way to solve this issue is
[editing the `hosts` file](
https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2#--editing-hosts-file)
on your machine, adding `192.168.1.222 example.com` IP-hostname pair.
This tells your machine to fuck asking google's DNS, the rule is right there,
`example.com` goes directly to the local server ip `192.168.1.222`.</br>
But if more devices should "just work" it is a no-go, since this just works
one the machine which `hosts` file was edited.</br>
So the answer is running a DNS server that does this
and a DHCP server that tells the devices on the network
to use this DNS.

# Prerequisites

* the machine that will be running it should have set static IP

# Files and directory structure

```
/etc/
├── dnsmasq.conf
├── hosts
└── resolve.conf
```              

* `dnsmasq.conf` - the main config file for dnsmasq where DNS and DHCP functionality is set
* `resolve.conf` - a file containing ip addresses of DNS nameservers to be used
   by the machine it resides on
* `hosts` - a file that can provide additional hostname-ip mapping

`hosts` and `resolve.conf` are just normal system files always in use on any linux
system.</br>
`dnsmasq.conf` comes with the dnsmasq installation.

# Installation

Install dnsmasq from your linux official repos.

# Configuration

`dnsmasq.conf`

```bash
# DNS --------------------------------------------------------------------------

# Never forward plain names (without a dot or domain part)
domain-needed
# Never forward addresses in the non-routed address spaces.
bogus-priv

# If you don't want dnsmasq to read /etc/resolv.conf
no-resolv
no-poll

cache-size=1000

# interface and address
interface=enp0s25
listen-address=::1,127.0.0.1

# Upstream Google and Cloudflare nameservers
server=8.8.8.8
server=1.1.1.1

# DNS entries ------------------------------------------------------------------

# wildcard DNS entry sending domain and all its subdomains to an ip
address=/example.com/192.168.1.2
# subdomain override
address=/plex.example.com/192.168.1.3

# DHCP -------------------------------------------------------------------------

dhcp-authoritative
dhcp-range=192.168.1.50,192.168.1.200,255.255.255.0,480h
# gateway
dhcp-option=option:router,192.168.1.1

# DHCP static IPs --------------------------------------------------------------
# mac address : ip address

dhcp-host=08:00:27:68:f9:bf,192.168.1.150

#dhcp-leasefile=/var/lib/misc/dnsmasq.leases
```

*extra info*

* `dnsmasq --test` - validates the config
* `dnsmasq --help dhcp` - lists all the DHCP options

You can also run **just DNS server**, by deleting the DHCP section
in the `dnsmasq.conf` to the end.</br>
Then on your router, in the DHCP>DNS settings, you just put in the ip address
of the dnsmasq host as the DNS server.

# resolv.conf

A file that contains DNS nameservers to be used by the linux machine it sits on.</br>
Since dnsmasq, a DNS server, is running right on this machine,
the entries just point to localhost.</br> 

`resolv.conf`
```
nameserver ::1
nameserver 127.0.0.1
```

Bit of an issue is that `resolv.conf` belongs to glibc, a core linux library.
But there are other network related services that like to fuck with it.
Like dhcpcd, networkmanager, systemd-resolved,...</br>
Ideally you know what is running on your host linux system, but just in case
`resolv.conf` will be flagged as immutable.
This prevents all possible changes to it unless the attribute is removed.

Edit `/etc/resolv.conf` and set localhost as the DNS nameserver, as shown above.

* Make it immutable to prevent any changes to it.</br>
  `sudo chattr +i /etc/resolv.conf`
* Check if the content is what was set.</br>
  `cat /etc/resolv.conf`

# /etc/hosts

`hosts`
```
192.168.1.2     docker-host 
192.168.1.1     gateway
192.168.1.2     example.com
192.168.1.2     nextcloud.example.com
192.168.1.2     book.example.com
192.168.1.2     passwd.example.com
192.168.1.2     grafana.example.com
```

This is a file present on every system, linux, windows, mac, android,... 
where you can assign a hostname to an IP.</br>
dnsmasq reads `/etc/hosts` for IP hostname pairs and adds them to its own
resolve records.

Unfortunately no wildcard support.</br>
But as seen in the `dnsmasq.conf`, when domain is set it acts as a wildcard
rule. So `example.com` stuff here is just for show. 

# Start the service

`sudo systemctl enable --now dnsmasq`

* Check if it started without errors</br>
  `journalctl -u dnsmasq.service`
* If you get "port already in use" error, check which service is responsible</br>
  `sudo ss -tulwnp`</br>
  stop and disable that service, for example if it is `systemd-resolved`</br>
  `sudo systemctl disable --now systemd-resolved`
* Make sure you **disable other DHCP servers** on the network,
  usually a router is running one.

# Test it

#### DHCP

Set some machine on the network to use DHCP for its network setting.</br>
Network connection should just work with full connectivity.

You can check on the dnsmasq host, file `/var/lib/misc/dnsmasq.leases`
for the active leases. Location of the file can vary base on your linux distro.

#### DNS

nslookup is a utility that checks DNS mapping,
part of `bind-utils` or `bind-tools` packages, again depending on the distro,
but also available on windows.

* `nslookup google.com`
* `nslookup docker-host`
* `nslookup example.com`
* `nslookup whateverandom.example.com`
* `nslookup plex.example.com`

### Troubleshooting

* **ping fails from windows when using hostname**</br>
  windows ping does not do dns lookup when just plain hostname is used</br>
  `ping meh-pc`</br>
  it's a [quirk](https://superuser.com/questions/495759/why-is-ping-unable-to-resolve-a-name-when-nslookup-works-fine/1257512#1257512)
  of windows ping utility.
  Can be solved by adding dot, which makes it look like domain name and this
  forces the dns lookup before pinging</br>
  `ping meh-pc.`</br>

* **slow ping of a hostname, but fast nslookup on a linux machine**</br>
  for me it was `systemd-resolved` running on the machine I was doing ping from.</br>
  It can be stopped and disabled.</br>
  `sudo systemctl disable --now systemd-resolved`

# Update

During host linux packages update.

# Backup and restore

#### Backup

Using [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the /etc directory which contains the config files.

#### restore

Replace the content of the config files with the one from the backup.
