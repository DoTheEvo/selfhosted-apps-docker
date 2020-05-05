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
└── dnsmasq.conf
```              

# Installation

* Install dnsmasq from your linux official repos.
* configuration
* enable and start the service</br>
  `sudo systemctl enable --now dnsmasq`

# Configuration


Configuration file location: /etc/dnsmasq.conf

`dnsmasq.conf`

```bash
# dont use resolv.conf as it gets changed by DHCP
resolv-file=/etc/resolv.conf.dnsmasq

# DHCP netmask
# CLients get 255.255.255.0 as netmask
dhcp-option=1,255.255.255.0

# default gateway
# clients get  192.168.1.251 as gateway
dhcp-option=3,192.168.1.69

# dns
# clients get 192.168.1.69 as DNS (this is the IP of the Pi itself)
dhcp-option=6,192.168.1.69


#you can assign fixed ip adresses to hosts based on mac address
dhcp-host=ma:ca:dr:e:ss:00,mycomp192.168.1.1,12h


# all hosts not identified by mac get a dynamic ip out of this range:
dhcp-range=192.168.1.120,192.168.1.200,12h 
```

# resolv.conf

Edit /etc/resolv.conf to send all requests to dnsmasq, then prevent c

* `nameserver 127.0.0.1`

Then make it immutable to prevent other services from making changes to it

* `chattr +i /etc/resolv.conf`

# /etc/hosts

dnsmasq reads all the DNS hosts and names from the /etc/hosts file,
so add your DNS hosts IP addresses and name pairs as shown.

127.0.0.1       dnsmasq
192.168.56.10   dnsmasq 
192.168.56.1    gateway
192.168.56.100  maas-controller 
192.168.56.20   nagios
192.168.56.25   webserver1


# Update

* [watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower)
 updates the image automaticly

* manual image update</br>
  `docker-compose pull`</br>
  `docker-compose up -d`</br>
  `docker image prune`
