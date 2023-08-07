# Free Hosting VPS 

###### guide-by-example

# Purpose & Overview

Free virtual private server hosting on a cloud.<br>
Here are github repos with details on various providers:

* [Cloud Service Providers Free Tier Overview](https://github.com/cloudcommunity/Cloud-Free-Tier-Comparison)
* [Stack on a budget](https://github.com/255kb/stack-on-a-budget)

So far I only run Oracle Cloud.<br>
Will add others if I will deal with them, or if Oracle fucks me over.

# Oracle Cloud

![logo](https://i.imgur.com/SVJ6dTP.png)

### What Free Tier Offers

As of 2023.

[Official docs](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)

* 1-2 instances of AMD based Compute VMs with 1/8 OCPU and 1 GB ram each<br>
  shape name: VM.Standard.E2.1.Micro
* 1-4 instances of 4 Arm-based Ampere A1 cores with 24 GB of ram to divide<br>
  shape name: VM.Standard.A1.Flex
* Block Volumes Storage, 200 GB total, default 50GB for boot of any VM
* 10 Mbps bandwidth  
* 10 TB per month outbound data transfer

### Registration

* A **credit card** is needed during the registration.
* **[Home region](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm)**
is picked and it can **not** be changed later.
Choise here will impact the IP address location and possibly availability of
free instances to create.
* I read that you wont be able to re-use credit card if you **terminate** your account.

Seen comments online that some just cant get the registration done.

### Instance creaction

![insance](https://i.imgur.com/nrR6Kx3.png)

Instances > Create instance

* Name - whatever
* Create in compartment - default
* Placement - default; `Always Free-eligible`
* Security - default - shield disabled
* Image and shape
  * VM.Standard.E2.1.Micro `Always Free-eligible`
  * Ubuntu 22.04 `Always Free-eligible`
* Networking - edit; create a new virtual cloud network; or pick existing one<br>
  same for subnet<br>
  Assign a public IPv4 address
* Add SSH keys - `Paste public keys`. Well it be good if you were not noob,
  and already have your ssh identiy and that you just paste your public key.<br>
  Noobs will need to pick `Generate a key pair for me`, then download
  both public and private keys and google out how to use them to
  SSH in the VM once it's running.
* Boot volume - keep default

You can ignore €1.85/month charge for Boot volume displayed, its a bug.
After the creation, in Billing & Cost Management - Subscriptions or Cost analysis
the ammount displayed should be 0€.


### Firewall settings

in examples here port will be 7777/tcp

**firewalld in ubuntu open port**

* `sudo apt-get update && sudo apt-get upgrade`
* `sudo apt install firewalld`
* `sudo firewall-cmd --zone=public --permanent --add-port=7777/tcp`
* `sudo firewall-cmd --reload`

**Oracle network settings ingress rule**

* Virtual Cloud Networks > VNC you got there > Subnet > Securty List > Ingress Rules
* A rule for port 22 should be there, to let in ssh.
* Add new rule 
  * Source Type - CIDR
  * Source CIDR - `0.0.0.0/0`
  * IP Protocol - `All Protocols`

![ingress](https://i.imgur.com/YouPN9n.png) 

**To test**

* ssh in to the VM
* `nc -l 7777` - starts a netcat server listening on port 7777/tcp
* go on site like [yougetsignal.com](https://www.yougetsignal.com/tools/open-ports/)<br>
  put in IP of the VM, port, test if you get `open`
* or from your linux machine `nc <ip-of-the-vm> 7777`,<br>
  write something, it should appear in the VM

If it works, then depending on the use, one can start securing stuff better.
For example, restricing from what public ip connection are accepted - 
ingress rule has `Source CIDR` set to lets say `353.749.385.54/32`

If set, the online test from a website will fail, but nc from
a machine with that public IP will work.

### Docker on ubuntu

For some reason [its not stupid simple](https://docs.docker.com/engine/install/ubuntu/)
to install docker on ubuntu. You are put to decisions.<br>
I picked the script way, which I guess dont get upated?

* `curl -fsSL https://get.docker.com | bash`

### Prevent reclaim if VM runs idle too much

![idle](https://i.imgur.com/q7mGQns.png)

I will not be running anything for now as a test,
if email about idle instance comes.

IF it comes the solution should be to put regular load on the VM.
This should do it.

* `echo "*/5 * * * * root timeout 46 nice md5sum /dev/zero" | sudo tee /etc/cron.d/dummy-load`

Some discussion on this

* [1](https://www.reddit.com/r/oraclecloud/comments/122b4gf/a_simple_cron_controlled_load_generator_for/)
* [2](https://www.reddit.com/r/oraclecloud/comments/125rege/what_to_run_on_always_free_to_prevent_idle/)

## Archlinux

![arch](https://i.imgur.com/eXGmmqR.png) 

I am used to archlinux and everything else feels wrong.<br>
So to get it as a VM on oracle cloud. 

* Download the latest qcow2 image<br>
  [https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2](https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2)
* Storage > Buckets > Bucket in the list > Upload
* Compute > Custom images > Import image 
  * Operating system - Generic Linux
  * Import from an Object Storage bucket
  * Image type - QCOW2
  * Paravirtualized mode

arch/arch for SSH login, recommend disabling password login and do IP restriction

Not tested but theres also this as option: 

* [Convert instructions](https://gist.github.com/zengxinhui/01afb43b8d663a4232a42ee9858be45e)
* [arch ARM](https://www.reddit.com/r/archlinux/comments/14iqb6h/how_to_install_arch_on_an_oracle_cloud_free_tier/)

### Links

Some youtube videos and articles 

* [youtube-1](https://youtu.be/NKc3k7xceT8)
* [youtube-2](https://youtu.be/zWeFD4NNF5o)
* [ryanharrison - oracle-cloud-free-server](https://ryanharrison.co.uk/2023/01/28/oracle-cloud-free-server.html)
