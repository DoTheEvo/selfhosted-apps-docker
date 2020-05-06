# dnsmasq

###### guide by example

![logo](https://i.imgur.com/SOa4kRd.png)

# Purpose

Lightweight DHCP and DNS server.

* [Official site](http://www.thekelleys.org.uk/dnsmasq/doc.html)
* [Arch wik](https://wiki.archlinux.org/index.php/dnsmasq)

# Files and directory structure

```
/etc/
├── dnsmasq.conf
├── hosts
└── resolve.conf
```              

* `dnsmasq.conf` - the main config file for dnsmasq where DNS and DHCP server is set
* `resolve.conf` - a file containing ip addresses of DNS nameservers to be used
   by the machine it resides on
* `hosts` - a file that can provide additional hostname-ip mapping

`hosts` and `resolve.conf` are just normal system files always in use on any linux
system.

# Installation

Install dnsmasq from your linux official repos.

# Configuration

Configuration file location: /etc/dnsmasq.conf

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

# DHCP and DNS interface and address
interface=enp0s25
listen-address=::1,127.0.0.1

# Upstream Google and Cloudflare nameservers
server=8.8.8.8
server=1.1.1.1

# DNS wildcards ----------------------------------------------------------------

# wildcard DNS entry sending domain and all its subdomains to an ip
address=/blabla.org/192.168.1.2
# subdomain override
address=/plex.blabla.org/192.168.1.3

# DHCP -------------------------------------------------------------------------

dhcp-range=192.168.1.51,192.168.1.199,255.255.255.0,480h
# gateway
dhcp-option=3,192.168.1.1

dhcp-authoritative

#dhcp-leasefile=/var/lib/misc/dnsmasq.leases
```

# resolv.conf

Contains DNS nameservers to be used by this linux machine.</br>
Since dnsmasq, a DNS server, is running right on this machine,
the entries should point to localhost.

Bit of an issue is that this file is often changed by various system services,
like systemd or dhcpcd.
To prevent this, `resolv.conf` will be flagged as immutable,
which prevents all possible changes to it unless the attribute is removed.

Edit /`etc/resolv.conf` and set localhost as the DNS nameserver.

`resolv.conf`
```
nameserver ::1
nameserver 127.0.0.1
```

Make it immutable to prevent any changes to it.

* `chattr +i /etc/resolv.conf`

Check if the content is what was set.

* `cat /etc/resolv.conf`

If it was changed by dhcpcd before the +i flag took effect, edit `/etc/dhcpcd.conf`
and add `nohook resolv.conf` at the end.</br>
Restart the machine, disable the immutability, edit it again,
add immutability, and check.

* `sudo chattr -i /etc/resolv.conf`
* `sudo nano /etc/resolv.conf`
* `sudo chattr +i /etc/resolv.conf`
* `cat /etc/resolv.conf`

# /etc/hosts

dnsmasq reads `/etc/hosts` for IP hostname pairs entries.
This is where you can add hostnames you wish to route to any ip you want.

Unfortunately no wildcard support.
But as seen in the `dnsmasq.conf` there is a wildcard section solving this,
so blabla stuff here is just for show. 

`hosts`
```
127.0.0.1       docker-host
192.168.1.2     docker-host 
192.168.1.1     gateway
192.168.1.2     blabla.org
192.168.1.2     nextcloud.blabla.org
192.168.1.2     book.blabla.org
192.168.1.2     passwd.blabla.org
192.168.1.2     grafana.blabla.org
```

# Start the services

Make sure you disable other DHCP servers on the network beforehand,
usually a router is running one.

`sudo systemctl enable --now dnsmasq`

# Test it

#### DHCP

Set some machine to use DHCP for its network setting.</br>
It should just work. 

You can check on the dnsmasq host, file `/var/lib/misc/dnsmasq.leases`
for the active leases. Location of the file can vary base on your linux distro.

#### DNS

nslookup is utility that checks DNS mapping, part of `bind-utils` or `bind-tools`,
again depending on the distro.

* `nslookup google.com`
* `nslookup gateway`
* `nslookup docker-host`
* `nslookup blabla.org`
* `nslookup whateverandom.blabla.org`
* `nslookup plex.blabla.org`

# Update

During host linux packages update.

# Backup and restore

#### Backup

Using [BorgBackup setup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the entire /etc directory
which contains the config files.

#### restore

Replace the config files with the one from backup
