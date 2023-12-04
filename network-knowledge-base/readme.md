# network-knowledge-base


* mac address
* ip address
* mask, mask notation
* gateway
* port
* packet and frame
* broadcast
* ARP
* NAT
* bridge, bridging
* switch, router, firewall
* Bandwidth
* DNS
* DHCP
* ICMP ping
* TCP / UDP
* HTTP
* SSH
* VPN
* [OSI/ISO model idea](https://www.reddit.com/r/networking/comments/2bazcl/i_dont_honestly_understand_the_osi_model_despite/cj45hih/)

[digital ocean](https://www.digitalocean.com/community/tutorials/an-introduction-to-networking-terminology-interfaces-and-protocols)<br>
[100 terms](https://www.makeuseof.com/networking-terms-glossary/)

![logo](https://i.imgur.com/ATNGPaJ.png)


# Network-hostnamess discovery / Zero-configuration networking / 

http://jaredrobinson.com/blog/upnp-ssdp-mdns-llmnr-etc-on-the-home-network/

 mDNS, NetBIOS, Samba, UPnP, Avahi, LLMNR, WINS,...

What a mess

Seems LLMNR is reliable and widly available everywhere for hostname resolution.
Even when wiki says its being phased out by microsoft.

Tested with wireshark. Pinging for a nonexisting hostname mans LLMNR
broadcast to every device on network is send asking who is that hostname.
Works same when pinging from archlinux or pinging from win8.1
 
[TCP vs UDP](https://youtu.be/jE_FcgpQ7Co)

# useful links

* https://dnsdumpster.com/<br>
  can check subdomains registered, ideal would be wildcard certificate


OSI Model 

* https://www.youtube.com/watch?v=2iFFRqzX3yE
