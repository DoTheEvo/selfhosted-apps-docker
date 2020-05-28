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

WireGuard is an opensource extremely simple, fast and modern VPN.
Written in C, with userspace implementation written in Go.<br>
WireGuard is included in linux kernel version 5.6 and newer.

While with WireGuard there is no server-clients model, there are just peers
connecting to each other, this setup will consider peer_A a server, 
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
* `wg-quick` - script for bringing up or down a WireGuard interface

### on linux client

Same as server

### on Windows or macOS clients

[Install the official application.](https://www.wireguard.com/install/)

*extra info:*<br>
Might be of interest server setup on 
[Windows](https://www.henrychang.ca/how-to-setup-wireguard-vpn-server-on-windows/)

### on Android or iOS

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
PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

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

This configuration when run creates a new network interface on the machine.

* PrivateKey - the key that was generated, will be used to encrypt traffic
* \# PublicKey - just a note, what is the public key of the private key
* Address - IP address on the created wireguard interface network,
  `/24` defines its mask as `255.255.255.0`
* ListenPort - port 
* PostUp/PostDown - define what should be done after interface is turned on and off
  in this case  firewall rules to let traffic through,
  only ipv4 in this setup
* [Peer] - section defining a peer, its public key
* AllowedIPs - 

### Start and enable the service

`sudo systemctl enable --now wg-quick@wg0`

# Configuration on clients

`TESTER-1.conf`
```bash
[Interface]
PrivateKey = kGqwq/+xy8CISBLfOZVOa8Za02MRzg5bN3Ddcf5KV2M=
Address = 10.200.200.2/32

[Peer]
PublicKey = fuCKVQU+x/jukZq3WH5yorJ4mE665dkv2HKN/0mH5hQ=
AllowedIPs = 10.200.200.0/24, 192.168.5.0/24
Endpoint = 63.123.113.495:51820
PersistentKeepalive = 25
```

![windows-client](https://i.imgur.com/T5oA2No.png)



# Troubleshooting



# Update

During host linux packages update.

# Backup and restore

#### Backup

Using [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the /etc directory which contains the config file.

#### restore

Replace the content of the config file with the one from the backup.


