# Beginners Speedrun to Selfhosting

###### guide-by-example

You want to selfhost stuff.<br>
You know little and want to start somewhere FAST!

## requirements

* a spare PC that will be the server
  * can be virtualmachine, makes it even easier.. virtualbox, hyperv.
* ability to google shit out
  * if the guide says do X, and steps seem insuficient to you, 
    you write that shit it in to google and add word youtube.
* ability to convince oneself the linux terminal is not scary.
  Its really trivial a slow monkey could copy paste few commands.

## install a linux on the server

[some video](https://www.youtube.com/watch?v=SyBuNZxzy_Y)

* **download linux iso**. For noobs I picked [EndeavourOS \(2GB\)](https://github.com/endeavouros-team/ISO/releases/download/1-EndeavourOS-ISO-releases-archive/EndeavourOS_Cassini_Nova-03-2023_R1.iso)
  * why that linux and not xxx? Fuck you, thats why. Not writing a novel here.
* **make bootable usb** from the iso, recommend use [ventoy](https://www.ventoy.net/en/doc_start.html)
  * literally just download; run; select usb; click install; exit; copy iso on to it
* **boot from the usb**, maybe on newer machines need to disable secure boot in bios
* **click through the installation**
  * pick online installer when offered
  * during install, there can be step called `Desktop` - pick `No Desktop`<br>
    or whatever, does not really matter
  * when picking disk layout choose wipe everything
  * username lets say you pick `noob`
* done

## basic setup of the linux server

SSH - a tiny application that allows you to execute commands
      from your comfy windows PC on the damn server 

* log in to the server and be in terminal
* ssh is installed by default, but disabled
* to check status - `systemctl status sshd`
* to **enable it** `sudo systemctl enable --now sshd`
* `ip a` or `ip r` - show [somewhere in there](https://www.cyberciti.biz/faq/linux-ip-command-examples-usage-syntax/#3)
  what IP address the server got assigned<br>
  lets say you got `192.168.1.8`,
  nope I am not explaining IP addresses
* done

*arrow up key in terminal will cycle through old comamnds in history*

## remote connect to the server

* **install** [mobaXterm](https://mobaxterm.mobatek.net/) on your windows machine
* use it to **connect** to the server using its ip address and username
  * [have a pic](https://i.imgur.com/lhRGt1p.png)<br>
* done

## installing docker

Docker - a thing that makes hosting super easy, people prepared *recipies*,
         you copy paste them, maybe edit a bit, run them

* **install docker-compose** - `sudo pacman -S docker-compose`
* **enable docker service** - `sudo systemctl enable --now docker`
* add your user to docker group so you dont need to sudo all the time<br>
  `sudo gpasswd -a noob docker`
* log out, log back in
* done

## using docker

Well, its time to learn how to create and edit files and copy paste shit
in to them, IN LINUX!<br>
Honestly could be annoying as fuck at first, but mobaXterm should make it easy
with the right mouse click paste.<br>
Nano editor is relatively simple and everywhere so that will be used.

* be in your home directory, the command `cd` will always get you there
* create directory `mkdir docker`
* go in to it `cd docker`
* create directory `mkdir nginx`
* go in to it `cd nginx`
* Oh look at you being all hacker in terminal, following simple directions
* create empty docker-compose.yml file `nano docker-compose.yml`
* paste in to it this, spacing matters
  ```
  services:

    nginx:
      image: nginx:latest
      container_name: nginx
      hostname: nginx
      ports:
      - "80:80"
  ```
* save using `ctrl+s`; exit `ctrl+x`
* run command `docker compose up -d`<br>
  will say the container started, if some error try `sudo docker compose up -d`
* on your windows machine go to your browser<br>
  in address bar put the ip of your server `192.168.1.8`, bam<br>

![nging_welcome](https://i.imgur.com/Iv0B6bN.png)

## undertanding what you just did 

* on linux server a docker container is running, its a webserver and it is
  accessible for others.<br>
  Most of selfhosted stuff is just webserver with some database.
* if this part is done that means that shit like hosting own netflix(jellyfin),
  or google drive/calendar/photos(nextcloud), or own password manager(vaultwarden)
  or own minecraft server(minecraft server) is just one `docker-compose.yml` away.
* you could almost abandon terminal at this point, just start googling portainer
  and you can be doing this shit through a webpage. I dont use it, but it
  got good I heard.

## undertanding what you did not get done

* this shit is on your own local network, not accessible from the outside.
  Cant call grandma and tell her to write `192.168.1.8` in to her browser
  to see your awesome nginx welcome running.
  She tells you that the dumb fuck you are you do not have public IP and ports
  forwarded.<br>
  To get that working is bit challenging, probably deserves own page,
  not realy speedrun, but thorough steps as shit gets sideways fast and people
  can dick around for hours trying wrong shit.
* everything here is just basic setup that breaks easily,
  server got dynamic IP, turn it off for a day and it might get a different ip
  assigned. Container is not set to start on boot,... 
* you dont understand how this shit works, fixing not working stuff be hard,
  but now you can start to consume all the guides and tutorials on
  docker compose and try stuff...
