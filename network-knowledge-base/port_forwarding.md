# Port Forwarding Guide

# What is a port

Ports solve the problem of how to make many applications communicate over
the network simultaneously.

A port is **a number** between [1 - 65,535] that gets assigned by the OS
to any application that wants to communicate over the network.
This number is then added to every **packet** that is transmitted by that application.
The system knows that any **respone** packets with that port number belong 
to that one application.

![pic_port_header](https://i.imgur.com/pXqs2Rg.png)

# How NAT / firewall works

* It **allows outgoing** communication on any port.
* But **drops incoming** traffic unless it is a response to communication
  initialized from the inside.

This is not really some security effort, the router just literally has no idea
where to send it...

<details>
<summary><b>More details</b></summary>

NAT is implemented in your router.<br>
It allows communication between two networks.
It makes your **LAN side** devices able to connect with the
outside world - **WAN side,** through one public IP.
All that the "the internet" sees is one device it communicates with,
but the LAN side can have hundreds of them.

<!-- ![pic_nat](https://i.imgur.com/QGO5bO6.png) -->

When you visit some website you initialize the communication.

* Your browser picks a random port as the **source port** and sends a request at some IP
using a well known https port 443 as the **destination port**
* Then the browser is waiting for a response at that random port.
* This traffic goes through your router and all that info is kept for a time in its state table.
* This allows it to know that when packets start coming from that IP, with that
source port number now being the destination port, it is a response and it
know where to send it.

Youtube explanation videos if you want deeper dive:

* [NAT - Network Address Translation.](https://www.youtube.com/watch?v=RG97rvw1eUo)
* [Public IP vs. Private IP and Port Forwarding](https://www.youtube.com/watch?v=92b-jjBURkw)

</details>

# Double NAT (CGNAT)

<!-- ![pic_cgnat](https://i.imgur.com/z697REf.png) -->

**Bad News.**<br>
It is very likely that even when you do everything 100% correctly,
you still wont get your ports open.<br>
The reason being that you are behind double NAT.
**Your ISP** - internet service provider, has you behind its own NAT device
and that WAN side of your router is not really "the internet" but ISPs LAN side. 

A way to try and check, is looking up your [public IP online](http://icanhazip.com/)
then loging on your router and finding somewhere the IP address of your WAN interface.
If they are the same then your are not behind double NAT and port forwarding 
will work straight away.<br>
If they differ and some local IP is there, then there is still a chance it will work,
but you wont know till you try.

But if you are failing to make port forwarding work, it's time to call your ISP
and inquire about public IP, how much would it cost.
It can be few € extra to your monthly bill, or a one time payment,
or they just enable it for you for free.. you dunno till you call.

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
* **IP address** is required, so that the router knows where to send traffic
  that comes to that external port.
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

![port_listener](https://i.imgur.com/A9fxIbi.png)

* [Find the ip address](https://www.youtube.com/results?search_query=how+to+find+ip+address+windows)
  of the machine you are planning to use for the test.
* Follow the instruction in Port forwarding section of this guide
  and forward port `666` to the IP of that machine.
* Download [Port Listener](https://www.rjlsoftware.com/software/utility/portlistener/).
* Run Port Listener, set port `666`, press Start.
  * If a windows firewall notification pops up with a question, answer yes.
* Go to [portchecker.co](https://portchecker.co/), set the port to 666 and press Check.

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
