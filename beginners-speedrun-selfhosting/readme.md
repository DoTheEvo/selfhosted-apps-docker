# Beginners Speedrun to Selfhosting

###### guide-by-example

You want to selfhost stuff.<br>
You know little and want to start somewhere, FAST!

# Requirements

* A **spare PC** that will be the server. Can be a **virtualmachine**.
* **Google** and **chatGPT**.<br>
  If the guide says do X and the steps seem insufficient, 
  you google that shit and add the word **youtube**,
  or you ask chatGPT few questions.

# Common terminology

* `repository` - a place from which linux distro installs stuff
* `root` - name for an administrator account in linux,
  but also can be a place - top level path
* `sudo` - [executes](https://www.explainxkcd.com/wiki/images/b/b1/sandwich.png)
  command as root with all privilages

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
  * This means no graphical interface, just command line.

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

### Install few packages

Onnce you are comfortably connected install some handy utilities,
only **curl** is really needed.

`sudo apt install curl neofetch btop ncdu`

* curl - utility to download stuff, useful in the next section
* [neofetch](https://i.imgur.com/VlSAr59.png) - shows general info about the machine
* [btop](https://i.imgur.com/HS0gsYQ.png) - resource monitoring and task manager
* [ncdu](https://i.imgur.com/P6fIonK.png) - disk space use

# Install docker

![docker_logo](https://i.imgur.com/6SS5lFj.png)

**Docker** - a thing that makes hosting super easy. People prepared *recipes*,
         you copy paste them, edit a bit, run them. [ChatGPT](https://i.imgur.com/eyWePqj.png).

* **install docker** - `sudo curl -fsSL https://get.docker.com | bash`<br>
  The above method is called
  [Install using the convenience script](https://docs.docker.com/engine/install/debian/#install-using-the-convenience-script)
  cuz oldman Debian cant be bothered to keep docker up to date in its repos.
* add your user to docker group so you dont need to sudo all the time<br>
  `sudo gpasswd -a noob docker`
* log out - `exit`, log back in
* intall [**ctop**](https://github.com/bcicen/ctop) to get some basic monitoring and management.<br>
  Unfortunately ctop is also not in debians repositories, so uglier
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

# Moving beyond terminal

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

# understanding what you just did 

* On a linux server a docker container is running, its a webserver and it is
  accessible for others on your network.<br>
  Most of selfhosted stuff is just webserver with some database.
* If this part is done that means that shit like hosting own netflix(jellyfin),
  or google drive/calendar/photos(nextcloud), or own password manager(vaultwarden)
  or own minecraft server(minecraft server) is just one `docker-compose.yml` away.

# understanding what you did not get done

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

## where to go from here

Can check out [this repo](https://github.com/DoTheEvo/selfhosted-apps-docker)

It has tiny section for noobs, with few links to docker tutorials.<br>
You should get some understanding of docker networks going,
making sure you create custom named one and use that in your compose files.
Then its time to start trying stuff like bookstack or jellyfin or minecraft.
