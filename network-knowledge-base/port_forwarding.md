# Port Forwarding Guide

# What is a port

An IP address identifies specific machine on a network,
**a port** identifies specific **application** running on that machine.

A port is **a number** between [1 - 65,535] that is assigned by the OS
to any application that wants to communicate over the network.
Can be choosen at random, can be hard set.

![pic_port_header](https://i.imgur.com/TM0pOQN.png)

# How NAT / firewall works

* By default, it **allows outgoing** communication on any port.
* But **drops incoming** traffic unless it is a response to communication
  initialized from the inside.

This is not really some security effort, the router just literally has no idea
where to send it...

<details>
<summary><b>More details</b></summary>

NAT is implemented in your router.<br>
It makes your **LAN side** devices able to connect with the
outside world - **WAN side,** through one public IP.
"The internet" *sees* just one device it communicates with,
at least at this network level. 

![pic_nat](https://i.imgur.com/Nk7u4MP.png)


#### LAN side initialized communication

* You visit a website, let's say `youtube.com`
* Your browser has some random port assigned by the OS,
  this will be the **source port**.
  The local IP address of the machine it runs on will be the **source IP**
* Browser/OS ask DNS servers for IP address of `youtube.com`,
  the answer is `142.250.191.78` - **destination IP**
* Youtube is a website, standard for https is using port `443` - **destination port.**
* All requred information are there. Destination[ip & port] Source[ip & port].
* Packets are send.
* The browser now waits for a response at that random port.
* Since the router is the **default gateway**, thats where the packets arrive. 
* The router saves all that info in its state table for a time, could be seconds,
  could be days depending on protocol and [state](https://serverfault.com/a/481909).
* Router doing the NAT now replaces the **source IP address** of that one machine,
  with its own wan IP address,
  it might also change source port but that is not as important,
  and sends it out in the direction of the **destination IP**.
* Response comes back, router knows it is a response because it's coming from the 
  IP that it contacted recently and the **destination port** it uses is the same
  number that was used as the source port.
* It checks the state table for the **original source IP and source port**,
  put them in, now as destination and off the packets go.
* The browser receives response on its assigned port, from the IP it contacted.

#### WAN side initialized communication

* Want to connect to a jellyfin server to watch some movies from browser.
* You know the IP address or the url.
  You also expect it to run on default port jellyfin uses `8096`
* The browser makes the request.
* The router sees it coming at port `8096`, but where does it send it?
  There is nothing in the state table, that would tell it.
* So it drops it, unless there is a port forwarding rule that says
  that if something comes to port `8096` send it to this local ip address
  and at that port...  

Youtube explanation videos if you want deeper dive:

* [NAT - Network Address Translation.](https://www.youtube.com/watch?v=RG97rvw1eUo)
* [Public IP vs. Private IP and Port Forwarding](https://www.youtube.com/watch?v=92b-jjBURkw)

---
---

</details>

# Double NAT (CGNAT)

<!-- ![pic_cgnat](https://i.imgur.com/z697REf.png) -->

**Bad News.**<br>
It is very likely that even when you do everything 100% correctly,
you still wont get your ports open.<br>
The reason being that your machine is behind double NAT.
**Your ISP** - internet service provider, has you behind its own NAT device
and that WAN side of your router is not really "the internet", but ISPs LAN side. 

A way to try and check, is looking up your [public IP online](http://icanhazip.com/)
then log in to your router and finding somewhere the IP address of your WAN interface.
If they are the same then your are not behind double NAT and port forwarding 
will work straight away.<br>
If they differ and some local IP is there, then there is still a chance it will work,
but you wont know till you try.

But if you are failing to make port forwarding work, it's time to call your ISP
and ask about public IP, how much would it cost.
It can be few extra € to your monthly bill.

# Port forwarding

Finally. Right?!

You want to host something, lets say a minecraft server.<br>
You set it all up, you give your public IP address to others and they try to connect,
but your router blocks them. It's a connection initialized from the outside.

So you need to tell your router/firewall to let through the traffic that comes to
minecraft default port - `25565` and where to send it on your LAN,
to the local IP of your minecraft server.

![diagram_port_forw_minecraft](https://i.imgur.com/PNR32Mz.png)

#### Examples of port forward rule

* [Asus](https://i.imgur.com/brs9Mr6.png)
* [TPlink](https://i.imgur.com/FNS2xCj.png)
* [ubiquiti](https://i.imgur.com/D04HVJc.png)

How to actually create that port forward rule depends on router/firewall model.

Generally what to expect

* It would be called port forwarding, or a virtual server, or be under NAT section.
* **The port** on which to expect traffic is obviously a core information,
  sometimes it is called a service port or an external port.
* **IP address** is required, so that the router knows where on the LAN side
  to send traffic that comes to that external port.
* The setup might offer option for **internal port**,
  this can be often left empty, or the same port number is put there.<br>
  It is there to give you option to run stuff on your LAN network on a different
  port than the one you open to the world. Like your webserver is `80`,
  but you open to the world port `12250` or whatever.
* **The protocol** - TCP or UDP, if dunno **select both / all**<br>
  You don't need to fear you are opening too much, if there is no service
  running on that port for that protocol it is same as a closed port.

# Testing if port forwarding works

![port_check_web](https://i.imgur.com/d5fNnCX.png)

First you need to understand that unless there is some application running
that answers on that port, all tests will come back as - closed port.

For testing we can use websites that will test if a port is open at specified public IP.

* [portchecker.co](https://portchecker.co/)
* [yougetsignal.com](https://www.yougetsignal.com/tools/open-ports/)

## Windows

* [Find the local ip address](https://www.youtube.com/results?search_query=how+to+find+ip+address+windows)
  of the machine you are planning to use for the test.
* Follow the instruction in Port forwarding section of this guide
  and forward port `666` to the IP of that machine.
* Download [Port Listener](https://www.rjlsoftware.com/software/utility/portlistener/).
* Run Port Listener, set port `666`, press Start.
  * If a windows firewall notification pops up with a question, answer yes.
* Go to [portchecker.co](https://portchecker.co/), set the port to 666 and press Check.

![port_listener](https://i.imgur.com/A9fxIbi.png)

In windows it is also pretty useful knowing that you can go 
`Task Manager` > `Performance` > `Open Resource Monitor` > `Network` Tab 

There unroll `Listening Ports`
and you should find there - `listener.exe` with port `666` and firewall status
should be *allowed, not restricted*

![windows_port_check](https://i.imgur.com/putdef0.png)

## Linux

* find your ip address - `ip r`
* Follow the instruction in Port forwarding section of this guide
  and forward port `666` to the IP of that machine.
* try running netcat - `nc `<br>
  * if it is not installed, get it for your distro,
    for arch it's `openbsd-netcat`, for debian it's `netcat-openbsd`,
    for fedora it's `netcat`
* execute `sudo nc -vv -l -p 666`
* Go to [portchecker.co](https://portchecker.co/), set the port to 666 and press Check.


## UDP port test

UDP is kinda special cuz it's session-less, so you need to actually communicate
through it to test it.

* on a linux machine on LAN - `sudo nc -vv -u -l -p 666`
* on a linux machine somewhere out there - `nc -u the_public_ip_goes_here 666`
* write something and it should appear on the other side
