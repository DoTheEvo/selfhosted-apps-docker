# Port Forwarding how to

You want to open something on your network to the world.

# What is a port

Ports solves the problem on how to make many applications communicate over
the network simultaneously.

A port is a number between 0 - 65,535 that gets assigned to any application that wants
to communicate over the network. This number is then added to every packet
that is transmitted by that application. The system knows that any respone
packets with that port number are to be send to that one application.

# How firewall works

A firewall knows direction and state of traffic.

* It allows outgoing communication on any port.
* But the incoming traffic gets dropped on all ports, unless it is a response 
to communication initialized from the inside.

<details>
<summary><b>More details</b></summary>

* When you visit some website you initialize the communication.
* Your browser picks a random port as the **source port** and sends a request at some IP
using a well known https port 443 - the **destination port**
* Then the browser is waiting for a response at that random port.
* This traffic goes through your firewall and all that info is kept in its state table.
* This allows firewall to know that when packets start coming from that IP, with that
source port number now being a destination port, it is a response and let it through.

</details>

# Port forwarding

What if you want to host something, lets say a minecraft server.<br>
You set it all up, you have your IP address known to others and they try to connect,
but your firewall blocks them. Its a connection initialized from the outside.

So you need to tell your router/firewall to let through traffic that comes to
minecraft default port - `25565` and where to send it on your LAN,
to the local IP of your minecraft server.

![diagram_port_forw_minecraft](https://i.imgur.com/PNR32Mz.png)

### Examples of port forward rule

How to actually create that port forward rule depends on router/firewall model.
It can be easy, it can be bit complicated.

Generally what to expect

* would be called port forwarding or a virtual server
* **IP address** is a core information, it is your LAN side machine IP on which
  your stuff runs.
* Another essential is **the port** on which to expect traffic,
  sometimes called a service port or an external port
* it might offer option for **internal port**, this can be often left empty 
  if port on which your stuff on server is running is the same as the one you
  are opening to the world. But this gives you option to open port 3333 of firewall
  but on your LAN machine have port 80 actually being used.
* **protocol** - TCP or UDP, if dunno **select both / all**, its safer for the initial setup and testing

# Testing if it works

### Windows

There are sites that will test if your port is open, but you need to run
some service at that port.

* [Port Listener](https://www.rjlsoftware.com/software/utility/portlistener/)
* [yougetsignal.com](https://www.yougetsignal.com/tools/open-ports/) or
  [portchecker.co](https://portchecker.co/) or


### Linux

* netcat 
