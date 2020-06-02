# WireGuard

# Work in progress

###### guide-by-example

![logo](https://i.imgur.com/IRgkp2o.png)

# Purpose & Overview

VPN.<br>
When you need to connect to a machine/network over the internet, securely.<br>

* [Official site](https://www.wireguard.com/)
* [Github](https://github.com/WireGuard)
* [Arch wiki](https://wiki.archlinux.org/index.php/WireGuard)

WireGuard is an opensource simple, fast and modern VPN.<br>
Written in C, with userspace implementation written in Go.<br>
WireGuard is included in linux kernel version 5.6 and newer.

WireGuard works at layer 3 and uses UDP protocol.<br>
While with WireGuard there is no server-clients model, there are just peers
connecting to each other, this gudie will setup peer_A as a server listening at a port, 
and clients will be connecting to it.

This setup runs directly on the host machine, not in a container.<br>
Most of the stuff here is based on Arch wiki and 
[this tutorial](https://securityespresso.org/tutorials/2019/03/22/vpn-server-using-wireguard-on-ubuntu/).

# Files and directory structure

```
/etc/
└── wireguard/
    └── wg0.conf
```              

# Installation

### on linux server

Install `wireguard-tools` or whatever is the equivalent in your distro.<br>
The package should provide two command line utilities
 
* `wg` -  utility for configuration and management of WireGuard tunnel interfaces
* `wg-quick` - script for bringing up or down a WireGuard interface and provide
  some extra configuration functions

### on linux clients

Same as server

### on Windows or macOS clients

[Install the official application.](https://www.wireguard.com/install/)

*extra info:*<br>
Might be of interest server setup on 
[Windows](https://www.henrychang.ca/how-to-setup-wireguard-vpn-server-on-windows/)

### on Android or iOS devices

Install the official app from the stores.


# Configuration on linux server

* switch to root and go in to in /etc/wireguard<br>
  `su`<br>
  `cd /etc/wireguard`
* generate a private key<br>
  `wg genkey > peer_A.key`
* create a public key from the private key<br>
  `wg pubkey < peer_A.key > peer_A.pub`

Use the generated keys in the wg0.conf, in the `[Interface]` section.

`wg0.conf`
```bash
[Interface]
PrivateKey = AA9q7CkUG3MuKP1eyyJFGgKzACIJ1rRIkkWYAi3p3WM=
# PublicKey = fuCKVQU+x/jukZq3WH5yorJ4mE665dkv2HKN/0mH5hQ=
Address = 10.200.200.1/24
ListenPort = 51820
PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o enp0s25 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o enp0s25 -j MASQUERADE

[Peer]
# TESTER-1
# PrivateKey = kGqwq/+xy8CISBLfOZVOa8Za02MRzg5bN3Ddcf5KV2M=
PublicKey = eVolUbiYj1kY8neKiDnA+NPB2hhCcsGs7LNIhMvUYj0=
AllowedIPs = 10.200.200.2/32

[Peer]
# TESTER-2
# PrivateKey = QNc0dunuRQAjuKpFmRPqvPAysqpklctcdblqrazUT0o=
PublicKey = CAt7g42pPxgU5Lcc3uyNh5BmkITJS1K6XAoFbkhN6Qk=
AllowedIPs = 10.200.200.3/32
```

This configuration when run creates a new `wg0` network interface on the machine.

**[Interface]** - section defining `wg0` wireguard interface
* **PrivateKey** - the key that was generated, identifies the server,
  will be used to encrypt packets
* **\# PublicKey** - just a note, what is the public key of the private key
* **Address** - IP address on the created wg0 network interface,
  `/24` defines its mask as `255.255.255.0`
* **ListenPort** - port on which wireguard connects to the internet, using UDP protocol 
* **PostUp/PostDown** - section where one can define what should be done after
  the interface is turned on or off.<br>
  In this case forwarding traffic across the tunnel and enabling NAT for interface `enp0s25`
  which you want to replace with your own<br>
  This setup ipv4 only

**[Peer]** - section defining a peers
* **PublicKey** - public key of the peer
* **AllowedIPs** - IP addresses that you want to reach at the other end of the tunnel.<br>
  When `wg-quick` is run with these defined, a route is added in to the network stack
  that makes sure that if something wants IP address defined here, it is send to `wg0`.<br>
  Two peers can not have same IP set in there.<br>
  In this case we want to define only single IP of the client as being accessible, allowed through.

### Start and enable the service

`sudo systemctl enable --now wg-quick@wg0`

# Configuration on clients

`TESTER-1.conf`
```bash
[Interface]
PrivateKey = kGqwq/+xy8CISBLfOZVOa8Za02MRzg5bN3Ddcf5KV2M=
# PublicKey = eVolUbiYj1kY8neKiDnA+NPB2hhCcsGs7LNIhMvUYj0=
Address = 10.200.200.2/32

[Peer]
PublicKey = fuCKVQU+x/jukZq3WH5yorJ4mE665dkv2HKN/0mH5hQ=
AllowedIPs = 10.200.200.1/32, 192.168.5.0/24
Endpoint = 63.123.113.495:51820
```

**[Interface]** - section defining `wg0` wireguard interface
* **PrivateKey** - private key of the peer
* **\# PublicKey** - just a note, what is the public key of the private key
* **Address** - IP address on the created wireguard network interface,
  `/32` defines its mask as `255.255.255.255` - a single host

**[Peer]** - section defining a peer, in this case server peer_A
* **PublicKey** - public key of the server
* **AllowedIPs** - IP addresses that you want to reach at the other end of the tunnel.<br>
  When `wg-quick` is run with these defined, a route is added in to the network stack
  that makes sure that if something wants IP address defined here, it is send to `wg0`.<br>
  Two peers can not have same IP set in there.<br>
  In this client case, we want to be able to communicate with the wireguard server,
  so its IP is added, but also the entire local network at the end of the tunnel,
  so its entire range is added.
* **Endpoint** - public IP at which to find the WireGuard server across the internet

![windows-client](https://i.imgur.com/T5oA2No.png)

# Troubleshooting

* *can connct to the server, but not the LAN machines*<br>
  make sure you set **your** network interface in PostUp/PostDown section on the server

# Update

During host linux packages update.

# Backup and restore

#### Backup

Using [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the /etc directory which contains the config file.

#### restore

Replace the content of the config file with the one from the backup.


