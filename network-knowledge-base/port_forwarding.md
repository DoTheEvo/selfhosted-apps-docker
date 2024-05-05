# Port Forwarding how to

You want to open something on your network to the world.

# What is a port

A number between 0 - 65,535 that gets assigned to any application that wants
to communicate over the network. This number is then added to every packet
that is transmitted by that application. The system knows that any respone
packets marked by that port number are to be send to that one application.

This solved the problem on how to make many applications communicate over
the network simultaneously.

# How firewall works

* Firewall allows outgoing communication on any port.
* But the incoming traffic gets dropped on all ports, unless it is a response 
to communication initialized from the inside.

So when you visit a website you initialized communication, you send requests
to some address an web browser is listening for a response at some port.

# What is port forwarding

What if you want to host something, lets say a minecraft server.<br>
You set it all up, you have your IP address known to others and they try to connect,
but your firewall blocks them. Its a connection initialized from the outside.

So you need to tell your router/firewall what to do when traffic comes to
minecraft default port - `25565`. It should be send to some IP address
on your local LAN where your minecraft server is running. 
