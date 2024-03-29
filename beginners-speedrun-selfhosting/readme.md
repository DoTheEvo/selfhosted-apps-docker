# Beginners Speedrun to Selfhosting

###### guide-by-example

You want to selfhost stuff.<br>
You know little and want to start somewhere, FAST!

#### Requirements

* A **spare PC** that will be the server, can be a **virtualmachine**.
* **Google** and **chatGPT**.<br>
  If the guide says do X and the steps seem insufficient, 
  you google that shit and add the word **youtube**,
  or you ask chatGPT few questions.

#### Common terminology

* `repository` - a place on the internet from which linux distro installs stuff.
* `root` - a name for an administrator account in linux.
  Can also mean a place - top level path, like `c:\` is top in windows,
  root - `\` is top level in linux.
* `sudo` - [executes](https://www.explainxkcd.com/wiki/images/b/b1/sandwich.png)
  command as root with all privilages.

# Install a Linux

![debian_logo](https://i.imgur.com/LHdGx2S.png)

* **Download linux iso**. I picked [Debian\(650MB\)](https://www.debian.org/)
  * *Why that linux and not xxx linux?*<br>
  * Fuck you, thats why. I am not writing a novel here.
* Make a **bootable usb** from the iso, [ventoy](https://www.ventoy.net) is recommend. [ChatGPT](https://i.imgur.com/gODUfJm.png).
  * [Download](https://www.ventoy.net/en/download.html) ventoy; extract;
    run `Ventoy2Disk.exe`; select a usb; click install; exit;
  * Copy the Debian iso on to the usb as you would any file.
* **Boot from the usb**, maybe on newer machines need to disable secure boot in bios
* **Click through the installation**
  * During first time install, would recommend actually reading whats written on screen each step.<br>
    Theres also plenty of [youtube videos,](https://www.youtube.com/results?search_query=installing+debian&sp=EgIIBQ%253D%253D)
    which go in to [details](https://youtu.be/rf3EN7e-34g?t=419).
  * Leave `root` password **empty**, so that sudo is installed automatically
    * this will disable root account, if you would want it, just set password for root<br>
      `sudo passwd root`
  * For username lets say `noob` with password `aaa`
  * During software selection [uncheck everything](https://i.imgur.com/MKrPMx2.png)
    except:
      * SSH server
      * standard system utilities<br>
  
This linux will have no graphical interface, just command line.

# SSH

![ssh_pic](https://i.imgur.com/ElFrBog.png)

**SSH** - a tiny application that allows you to execute commands from your comfy
windows PC on the damn server. [ChatGPT](https://i.imgur.com/vJjJxZT.png).

During Debian install you should have had SSH server checked,
so it would be installed automatically.
If you missed it, install it with - `sudo apt install ssh`

Now to **find IP address** of the machine so we can remotely connect to it.

* Log in  `noob` / `aaa` and be in terminal.
* `ip r` - shows [at the end the IP](https://i.imgur.com/eGkYmKB.png) of the machine<br>
  lets say you got `192.168.1.8`<br>
  Nope I am not explaining IP addresses.

To [check status](https://i.imgur.com/frlyy6P.png) of ssh - `systemctl status sshd`

### Remote connect to the server

![mobasterm_logo](https://i.imgur.com/aBL85Tr.png)

* **install** [mobaXterm](https://mobaxterm.mobatek.net/) on your windows machine
* use it to **connect** to the server using its ip address and username
  * [have a pic](https://i.imgur.com/dHncQBv.png)
  * [have a video](https://youtu.be/A7pHiPgW2u8&t=10s)

# Install docker

![docker_logo](https://i.imgur.com/6SS5lFj.png)

**Docker** - a thing that makes hosting easier. People prepared *recipes*,
  you copy paste them, edit a bit, run them. Bam a container is running
  and answering at some IP. [ChatGPT](https://i.imgur.com/eyWePqj.png).

* **install docker** - `sudo wget -O- https://get.docker.com | bash`<br>
  The above method is called
  [Install using the convenience script](https://docs.docker.com/engine/install/debian/#install-using-the-convenience-script),
  cuz oldman Debian cant be bothered to keep docker up to date in its repos.
* **add your user to docker group** so you dont need to sudo all the time<br>
  `sudo gpasswd -a noob docker`
* log out - `exit`, log back in so the group change takes effect
* **install [ctop](https://github.com/bcicen/ctop)** to get some basic monitoring and management.<br>
  Unfortunately ctop is also not in Debians repositories, so uglier
  [two commands](https://github.com/bcicen/ctop?tab=readme-ov-file#linux-generic) to install it:
  * `sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop`
  * `sudo chmod +x /usr/local/bin/ctop`

# First docker compose

![nging_welcome](https://i.imgur.com/Iv0B6bN.png)

Well, its time to learn how to create and **edit files** and copy paste shit
in to them, IN LINUX!

Honestly could be annoying, but mobaXterm should make it easier
with that left directory pane that lets you move around,
and the right/middle mouse click for paste.<br>
But here are general linux commands to move around, using `nano` editor
for editing files as it is simple and everywhere.

*extra info:* `arrow-up key` in terminal will cycle through old commands in history

* Be in your home directory, the command `cd` will always get you there.
 [ChatGPT.](https://i.imgur.com/i32So7T.png)
* Create directory `mkdir docker`
* Go in to it `cd docker`
* Create directory `mkdir nginx`
* Go in to it `cd nginx`
* Oh look at you being all hacker in terminal, following simple directions
* Create empty docker-compose.yml file `nano docker-compose.yml`
* Paste in to it this *recipe*, spacing matters
  ```
  services:

    nginx:
      image: nginx:latest
      container_name: nginx
      hostname: nginx
      ports:
      - "80:80"
  ```
* Save using `ctrl+s`; exit `ctrl+x`
* Run command `sudo docker compose up -d`<br>
  [This is what it should look like](https://imgur.com/a/vtHYNr9)
* You can run `ctop` to see container status, resource use, logs,
  details, or to exec in to the container. [Like so.](https://imgur.com/a/ChGjk7i)
* on your windows machine go to your browser<br>
  in address bar put the ip of your server `192.168.1.8` bam<br>
  You should see the pic above - **Welcome to nginx!**

*extra info:* it should actually be`192.168.1.8:80`,
with the port 80 we see in the compose being used in the url too.
But since port 80 is the default http port, it is what browsers go for anyway.

### understanding what you just did 

* On a linux server a docker container is running, its a webserver and it is
  accessible for others on your network.<br>
  Most of selfhosted stuff is just webserver with some database.
* If this part is done that means that shit like hosting own netflix(jellyfin),
  or google drive/calendar/photos(nextcloud), or own password manager(vaultwarden)
  or own minecraft server(minecraft server) is just one `docker-compose.yml` away.

### understanding what you did not get done

* this shit is on your own local network, not accessible from the outside.
  Cant call the grandma and tell her to write `192.168.1.8` in to her browser
  to see your awesome nginx welcome running.
  She tells you that the dumb fuck you are, you do not have public IP and ports
  forwarded.<br>
  To get that working is bit challenging, probably deserves own page,
  not really speedrun, but thorough steps as shit gets sideways fast and people
  can dick around for hours trying wrong shit.
* everything here is just basic setup that breaks easily,
  server got dynamic IP, turn it off for a weekend and it might get a different ip
  assigned next time it starts. Nginx container is not set to start on boot,... 
* you dont understand how this shit works, deploying more complicated stuff,
  fixing not working stuff be hard, but now you can start to consume all
  the guides and tutorials on docker compose and try stuff...

# WebGUI

* *my recommendation is to not abandon the ssh + terminal. Persevere.
  Use it, make it comfortable, natural, not foreign and bothersome.
  This is what gets you proficiency and ability to solve problems...
   but I understand*

Several options to manage docker using a website.

* Portainer CE - the most popular, deployed as a container, they started to push hard
  their paid version so fuck em
* **CasaOS** - simple install, seems nice and growing in popularity
* **Dockge** - a very new one, but seems nice and simple
* TrueNAS SCALE - NAS operating systems with docker managment
* openmediavault - NAS operating systems with docker managment
* Unraid - paid NAS operating systems with docker managment

# CasaOS

[The official site](https://casaos.io)

Easy to also create public shares, easy to deploy docker popular docker
containers from their *"app store"*

#### Installation

* `docker compose down` any containers you run, or remove them in ctop, or
  do clean Debian install again
* To install CasaOS execute:<br>
  `sudo wget -O- https://get.casaos.io | sudo bash`
* Afterwards, it tells the ip to visit.
* First login set credentials

---

<details>
<summary><b><font size="+1">Create a network share </font></b></summary>

[share.webm](https://github.com/DoTheEvo/selfhosted-apps-docker/assets/1690300/c640665f-9400-4cf2-949b-07753ad8a86c)

</details>

---
---

<details>
<summary><b><font size="+1">Deploy Crafty - Minecraft server manager</font></b></summary>

[crafty.webm](https://github.com/DoTheEvo/selfhosted-apps-docker/assets/1690300/ea163089-5329-4530-8361-83bb526fbe2d)

</details>

---
---

<details>
<summary><b><font size="+1">Deploy Jellyfin - selfhosted netflix</font></b></summary>

[jellyfin.webm](https://github.com/DoTheEvo/selfhosted-apps-docker/assets/1690300/0dac601a-f159-4745-abc1-1279b25875dd)

</details>

---
---

<details>
<summary><b><font size="+1">Deploy something not in the app store</font></b></summary>

test

</details>

---
---


# Dockge

![dockge_pic](https://i.imgur.com/Vh0JN5F.png)

Beginners hate terminal.
[Dockge](https://github.com/louislam/dockge) comes to the rescue with its web interface.

Same as nginx example was deployed, we deploy dockge
using slightly edited compose file from their
[github page.](https://github.com/louislam/dockge/blob/master/compose.yaml)

* Create a new directory dockge `mkdir ~/docker/dockge`
* Go in to the docker directory `cd ~/docker/dockge`
* Create an empty docker-compose.yml file `nano docker-compose.yml`
* Paste the *recipe*, spacing matters
  ```
  services:
    dockge:
      image: louislam/dockge:1
      container_name: dockge
      hostname: dockge
      restart: unless-stopped
      ports:
        - "5001:5001"
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock
        - ./data:/app/data
        - /opt/stacks:/opt/stacks
      environment:
        - DOCKGE_STACKS_DIR=/opt/stacks
  ```
* Save using `ctrl+s`; exit `ctrl+x`
* Run command `sudo docker compose up -d`<br>
* on your windows machine go to your browser<br>
  in address bar put the ip of your server `192.168.1.8:5001` bam<br>

Now you can do stuff from webgui, pasting compose and .env files.


## where to go from here

Google and consume docker tutorials and videos and try to spinning up
some containers.<br>
Heres some stuff I encountered and liked.

* [8 min video on docker](https://www.youtube.com/watch?v=rIrNIzy6U_g)
* [docker compose cheat sheet](https://devopscycle.com/blog/the-ultimate-docker-compose-cheat-sheet/)
* [Good stuff](https://adamtheautomator.com/docker-compose-tutorial/)
* [https://devopswithdocker.com/getting-started](https://devopswithdocker.com/getting-started)
* [NetworkChuck](https://www.youtube.com/@NetworkChuck/videos)
  \- youtube channel
  has some decent stuff, specificly [this docker networking](https://youtu.be/bKFMS5C4CG0)
  video is fucking great and the general
  [introduction to docker compose](https://youtu.be/DM65_JyGxCo) is good too.
* [Christian Lempa](https://www.youtube.com/@christianlempa/search?query=docker)
  \- lot of videos about docker


Check of course [this github repo you are in right](https://github.com/DoTheEvo/selfhosted-apps-docker)
for some stuff to deploy.

