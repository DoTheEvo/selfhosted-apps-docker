# VLANs Guide

![tagged_vlan_example_diag](https://i.imgur.com/l5IxAKf.png)

### Purpose of VLANs

Separation of a network in to smaller segments.<br>
This can improve securirty, ease of managment, latency in larger networks.

### Hardware

Whats required before thinking about vlans.

* **Managed switches** as oppose to cheaper typical *"dumb switches"*,
  as majority of the configuration of vlans is done on switches.<br>
* A **router/firewall/gateway** device that supports vlans.
  This will be the linchpin at the center, with separate settings
  for each vlan - being their gateway, providing them with separate dhcp,
  applying firewall rules between them,...<br>
  * **opnsense** - is what I [use](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/opnsense),
    installed as a virtual machine, but can be installed on any regular old pc,
    or a miniPC with two NICs.
  * **Ubiquiti UCG-Ultra** - solid go-to recommendation.
    <details>
    <summary>Reasons...</summary>
    * it is **very easy to configure**.
    * 100€.
    * ok hardware - 4x arm cores, 3GB RAM, informative lcd display, usb-c power.
    * full of features - vlans, wireguard VPN, cloud remote managment,
      geoblocking, basic IDPS, DNS base adblocking, unifi controller for wifi APs,... 
      </details>
  * **Mikrotik** devices are a good pick, but their configuration can be
    overwhelming. I gave up and use just their switches.


<details>
<summary><h3>Some basic networking knowledge is required.</h3></summary>

You should know about IP addresses, Mac addresses, packets, frames,
swiches, routers, about existance of first 4 OSI layers,..

* [What is OSI Model | Real World Examples](https://youtu.be/0y6FtKsg6J4)
* [OSI Model Deep Dive](https://youtu.be/oVVlMqsLdro)
* [CIDR notation](https://youtu.be/z07HTSzzp3o?t=746)
* [Layer 2 vs Layer 3 Switches](https://youtu.be/bdNS0K4Bt8U)

lets put here also vlan stuff

* [vlan theory video](https://youtu.be/MmwF1oHOvmg)
* [vlan theory video2](https://youtu.be/JszGeQPTo4w)
* [vlan networkacademy](https://www.networkacademy.io/ccna/ethernet/vlan-concept)
* [What is VLAN and how it works](https://www.etherwan.com/support/featured-articles/brief-introduction-vlans)
* [Network Virtualization: Beyond VLANs – Part 1: VLANs](https://infrastructureadventures.wordpress.com/2010/11/13/network-virtualization-beyond-vlans-part-1/)
* [What is PVID? VLAN explained Quick and Dirty](https://forflukesake.co.za/wp/531/vlan-pvid-explained-quick-and-dirty/)
---
---

</details>

### Two types of VLANs

* **Port based**<br>
  A simple separation of ports on a switch,
  as if you would cut it in to several smaller switches.
  This is boring, limiting and generally **useless**,
  as you would need to deal with extra cables, extra interfaces, extra hardware..
* **Tag based**<br>
  The real deal vlan. At layer2 a **vlan tag** is added to frames.
  It contains a **vlan ID** which is a number between 1 and 4094.
  These are used to create virtual networks that are separate
  from each other but share same hardware, same cables.<br>
  The standard is called **802.1Q**.

![frame_pic](https://i.imgur.com/pUq92ky.png)

Some aspects:

* **Tags** are added or removed from **frames** at physical ports,
  when entering or leaving switch.
* A tag is 4 bytes in size, contains [several pieces of info](https://i.imgur.com/86zeYgG.png),
  the most important being vlan ID.
* **Vlan ID** (VID) is just a number between 1-4094, often picked as
  multiplies of ten - 10, 20, 30, 40, ... with the ip address pool on that VLAN
  having it somewhere too.<br>
  Like vlan30 would be set as 192.168.30.0/24 or 10.30.30.0/24. 
* Tagged frames **get dropped** if they would arrive to a regular machine,
  not configured for vlans.

### The Core concept

The **absofucking essence** of VLANs is a clear understanding of two types
of ports - untagged and tagged.

![tagged_untagged_traffic](https://i.imgur.com/snTxTyf.gif)

* **Untagged ports**<br>
  Called untagged because frames coming in to a switch, or leaving the switch
  through that one port are not tagged. So that the end device can actually
  communicate without the need to be configured for vlans.<br>
  While the inbound frames, the ones entering the switch through this port
  are untagged at the moment of entering, they are tagged once inside the switch
  according to **PVID** settings for that port, so that they can exit only
  through other ports tagged with that same VLAN.<br>
  Untagged ports are **used for end user devices** unaware of vlans - computers,
  printers, ip cameras, IoT devices,...<br>
  These are sometimes called **access ports**, as thats cisco term for them.
  * **PVID** - Port Vlan ID<br>
    Is a setting on a port. Incoming frames entering switch that are not tagged
    get tagged with this PVID number.<br>
    It might feel weird that for an untagged port you are setting both VLAN ID
    and PVID when VLAN ID should be enough. It feels like duplication of effort...
    but its there to solve some hybrid cases.
* **Tagged ports**<br>
  Tagged frames going in and out of this kind of ports. Tagged port can carry many
  VLANs simultaneously if set so, or can carry just one.
  Purpose is to communicate with other vlan aware devices,
  like other switches, routers, servers/virtual machines, IP telephones,...<br>
  Of note is that setting a port to **vlan 4095** allows all vlans to traverse,
  though it can be manufacturer dependent, if its even allowed to set vlan above
  `4094`.<br>
  * **Trunk port**<br>
  A type of tagged port. The term is used for ports that carry multiple vlans,
  usually the ones connecting two switches, or a switch and a router.<br>
  A tagged port that is not a trunk port would be for example a port that carries
  just one vlan to a VoIP phone.
  * **Native vlan**<br>
    Frames belonging to native vlan leave the trunk port untagged.
    The initial reason for the existence of this is to allow older dumb switches
    to be part of the infrastructure, in between two managed ones.
    [Video.](https://youtu.be/Fmq1E1Qr2W4)

# Setting up VLANs on Routers

![vlan_pic_with_dhcp](https://i.imgur.com/nV27IlD.png)

Your vlan aware router wil be the linchpin at the center,
the gateway to the internet for all vlans, the dhpc server for all vlans,
the firewall for all vlans,...

#### The usual generic steps

* creating a new interface or a new network with a specific Vlan ID.
* setting what IP address / subnet the router will have on that network.
* setting the dhcp pool for for that network.
* maybe enable or restrict the traffic through firewall rules

<details>
<summary><h2>OPNsense - Router</h2></summary>

![opnsense_int](https://i.imgur.com/fz67oJj.png)

[Isolating Networks in OPNsense](https://youtu.be/TjXkWSjYqlM)

* **Add new VLAN**<br>
  `Interfaces: Other Types: VLAN`<br>
  Add; Device = empty; Parent = **LAN**; VLAN tag = `20`; VLAN priority = default;
  Description = `VLAN20WIFI`
* **Assign the new VLAN as an interface**<br>
  `Interfaces: Assignments`<br>
  Assign a new interface > pick the VLAN from dropbox; Description = `vlan_20_wifi`<br>
  Enter the newly created interface, Enable it; IPv4 Configuration Type = `Static IPv4`;
  IPv4 address = `10.20.20.1/24`
* **Setup dhcp servis on the new interface**<br>
  `Services: ISC DHCPv4: [VLAN20WIFI]`<br>
  Enable; From = `10.20.20.50` To = `10.20.20.200`; DNS servers = 10.20.20.1;
  Gateway = `10.20.20.1`
* **Firewall rule to enable traffic through**<br>
  `Firewall: Rules: VLAN20WIFI`<br>
  Source = `VLAN20WIFI net`; save as default is pass and everything

<details>

* [opnsense video](https://youtu.be/LMJeIUDlrHo)
* [pfsense video but applicable](https://youtu.be/SsaGeXx2qh0)

<summary><h5>If running opnsense as a virtual machine.</h5></summary>

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

</details>

<details>
<summary><h2>Ubiquiti Unifi - Router</h2></summary>

![opnsense_int](https://i.imgur.com/8pPHuX4.png)

Disgustingly simple.

Settings > Networks > New Virtual Network

* set `Name`
* turn off `Auto-Scale Network`
* set `Gateway IP/Subnet` which sets this routers IP on that vlan
* set `VLAN ID` = `20`
* pick if you want guest network or isolation or disable internet access on it
* `DHCP` set pool range

</details>

# Setting up VLANs on switches

What happens immediately after you enable VLANs on a switch?

* Everything should still work as before.
* All ports switch to be untagged ports. So they strip any vlan tags from
  outbound frames.
* PVID on all ports is set to 1, so that incoming frames get tagged as vlan 1,
  so all ports can communicate with each other.

What happens next is you pick a trunk port, the one communicating with the router
or a switch through which multiple vlan goes as set it accordingly to belong to
all vlans.<br>
Then pick which ports have device that should be together and separated from the
rest and set their vland and PVID.

<details>
<summary><h2>TP-Link - Switch</h2></summary>

![tplink_switch](https://i.imgur.com/u0INJ4C.gif)

Got [TL-SG108PE](https://www.tp-link.com/us/home-networking/8-port-switch/tl-sg108pe/)
thats a managed switch with PoE. At the moment the situation
is that opnsense LAN port is connected to port 7 and testing notebook
is connected to port 6.

* VLAN > 802.1Q VLAN > set port 7 as tagged and port 6 as untagged.
* VLAN > 802.1Q PVID Setting > set port 6 with vlan tag 20

Dunno what is the reason there are two settings, they say PVID is setting
specifically to tags incoming frames that come without any tag... but I cant
imagine a situation where one would want different number between these two.  

</details>

<details>
<summary><h2>MikroTik - Switch</h2></summary>

![mikrotik_switch](https://i.imgur.com/FMpl9TA.gif)


[a vlan guide](https://forum.mikrotik.com/viewtopic.php?t=143620)

* **Bridge** section is where all the settings are happening.<br>
  This setup is simple layer 2, no routing, not doing anything with interfaces.
* Have a **bridge**, create a new one if you have clean config<br>
  Assign all the physical ports to this bridge in **Bridge > Ports**
* Create **VLANs** in **Bridge > VLANs** that you want the switch be aware of.<br>
  Set which ports are tagged and which untagged for that vlan
  * untagged - frames leaving the port are normal - PCs, Printers, TVs,..
  * tagged - frames leaving the port are tagged - servers, gateways, wifi APs,...
* Set **PVIDs** for the ports in **Bridge > Ports**<br>
  PVIDs is about **untagged frames** going in to the switch,
  if they should be assigned VLAN tag as they move through switch.
  By default mikrotik switches give tag 1 to all ports.
* Enable VLAN Filtering on the bridge itself<br>
  **Bridge > Bridge > bridge** > VLAN section

</details>


<details>
<summary><h2>Ubiquiti Unifi - Switch</h2></summary>

![unifi_switch](https://i.imgur.com/Lf2UIY3.png)



</details>
