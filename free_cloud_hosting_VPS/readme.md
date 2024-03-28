# Free Hosting VPS 

###### guide-by-example

# Purpose & Overview

Free virtual private server hosting on a cloud.<br>
Here are github repos with details on various providers:

* [Stack on a budget](https://github.com/255kb/stack-on-a-budget)
* [Cloud Service Providers Free Tier Overview](https://github.com/cloudcommunity/Cloud-Free-Tier-Comparison)
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

* If none selected, pick Compartment in left column, default root
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

**Oracle network settings ingress rule**

* Virtual Cloud Networks > VNC you got there > Subnet > Securty List > Ingress Rules
* A rule for port 22 should be there, to let in ssh.
* Add new rule 
  * Source Type - CIDR
  * Source CIDR - `0.0.0.0/0`
  * IP Protocol - `All Protocols`

![ingress](https://i.imgur.com/YouPN9n.png) 


**firewalld in ubuntu open port**

in examples here port will be 7777/tcp

* `sudo apt-get update && sudo apt-get upgrade`
* `sudo apt install firewalld`
* `sudo firewall-cmd --zone=public --permanent --add-port=7777/tcp`
* `sudo firewall-cmd --reload`

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
* Storage > Buckets > Create Bucket > Defaults are fine  
* Pick the bucket from the list > Upload  the qcow2 arch image
* Compute > Custom images > Import image 
  * Operating system - Generic Linux
  * Import from an Object Storage bucket
  * Image type - QCOW2
  * Paravirtualized mode
  * Import image

Afterwards its going same as with any other instance.

arch/arch for SSH login, recommend disabling password login and do IP restriction

Not tested but theres also this as option: 

* [Convert instructions](https://gist.github.com/zengxinhui/01afb43b8d663a4232a42ee9858be45e)
* [arch ARM](https://www.reddit.com/r/archlinux/comments/14iqb6h/how_to_install_arch_on_an_oracle_cloud_free_tier/)

### Links

Some youtube videos and articles 

* [youtube-1](https://youtu.be/NKc3k7xceT8)
* [youtube-2](https://youtu.be/zWeFD4NNF5o)
* [ryanharrison - oracle-cloud-free-server](https://ryanharrison.co.uk/2023/01/28/oracle-cloud-free-server.html)

# GCE - Google Compute Engine

![logo-gce](https://i.imgur.com/Eau2Hm5.png)


### What Free Tier Offers

[Official docs](https://cloud.google.com/free/docs/free-cloud-features#compute)

As of 2023.

* 1 e2-micro VM instance; 0.25-2 vCPU (1 shared core); 1GB ram
* 30 GB disk storage (default 10GB)
* 600/300 Mbps bandwidth  
* 1 GB per month outbound data transfer

### Registration

Credit card is required.<br>
Otherwise it's smooth process as you likely have google account,
and if you have credit card tight to, its just few yes clicks.

### New VM instance in Free Tier

On the GCE console web

* Create a new project named whatever lowercase.
* Add your SSH key to be able to ssh in<br>
  left pane > metadata > SSH Keys > Edit > Add Item<br>
* Create a new virtual machine<br>
  left pane > Compute Engine > VM instances > Create new instance
  * it asks to enable Compute Engine API, enable it
  * Name
  * Region - must be one the three: `us-west1`, `us-central1`, `us-east1`
  * Zone - default
  * Machine series - `E2`
  * Machine type - e2-micro(2vCPU, 1 core, 1GB memory)
  * stuff left on default
  * Boot disk > Change
    * debian 12 (latest)
    * disk increase if desired, up to 30GB should be free
  * Firewall > allow both `http` and `https` traffic
  * CREATE

After few minutes new one with public IP listed should be listed.<br>
Test ssh in to it from your terminal.

