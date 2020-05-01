# Arch Linux installation to serve as a docker host

###### guide by example

![logo](https://i.imgur.com/SkENpGn.png)

# Purpose

Linux that will run docker.

This is not a very hand holding guide.</br>
Google for plenty of tutorials and youtube videos alongside arch wiki.

* [Official site](https://www.archlinux.org/)
* [Arch wiki install guide](https://wiki.archlinux.org/index.php/installation_guide)
* [Arch wiki docker entry](https://wiki.archlinux.org/index.php/docker)

# Files and directory structure

```
/home/
└── bastard/
    └── docker/
        ├── container-setup #1
        ├── container-setup #2
        ├── ...
```

# Make installation usb

* [wiki](https://wiki.archlinux.org/index.php/USB_flash_installation_media)

`sudo dd bs=4M if=archlinux-2020.05.01-x86_64.iso of=/dev/sdX status=progress oflag=direct`

The above command will fuck your machine up if you dunno what you are doing

# Boot from the usb

This is BIOS/MBR setup as I am running on and old thinkpad with a busted screen,
plus I like the simplicity of it.</br>
So if theres boot menu option choose non-uefi.

# Installation 

* create a single partition and mark it bootable</br>
  `cfdisk /dev/sda`
* build ext4 filesystem on it</br>
  `mkfs.ext4 /dev/sda1`
* mount the new partition</br>
  `mount /dev/sda1 /mnt`
* choose geographicly close mirror, ctrl+k deletes a line in nano</br>
  `nano /etc/pacman.d/mirrorlist` 
* install the base system </br>
  `pacstrap /mnt linux linux-firmware base base-devel linux linux-firmware grub dhcpcd`
* gnerate fstab</br>
  `genfstab -U /mnt > /mnt/etc/fstab`
* chroot in to the new system</br>
  `arch-chroot /mnt`
* install grub</br>
  `grub-install /dev/sda`</br>
  `grub-mkconfig -o /boot/grub/grub.cfg`
* remove the bootable media and restart the machine</br>
  `exit`</br>
  `reboot`

# Basic configuration after the first boot

* login as `root`</br>
* set password for root</br>
  `passwd`
* set hostname</br>
  `echo docker-host > /etc/hostname`
* add new user and set their password</br>
  `useradd -m -G wheel bastard`
  `passwd bastard`
* edit sudoers to allow users group wheel to sudo</br>
  `EDITOR=nano visudo`</br>
  *%wheel ALL=(ALL) ALL*
* check the network interface name</br>
  `ip link`
* enable aquiring dynamic IP</br>
  `systemctl enable --now dhcpcd@enp0s25`
* uncomment desidred locales in locale.gen</br>
  `nano /etc/locale.gen`</br>
* generate new locales and set one system wide</br>
  `locale-gen`</br>
  `localectl set-locale LANG=en_US.UTF-8`
* select timezone and set it permanent</br>
  `tzselect`</br>
  `timedatectl set-timezone 'Europe/Bratislava'`
* set hardware clock and sync using ntp</br>
  `hwclock --systohc --utc`</br>
  `timedatectl set-ntp true`
* setup a swap file</br>
  `fallocate -l 8G /swapfile`</br>
  `chmod 600 /swapfile`</br>
  `mkswap /swapfile`</br>
  `nano /etc/fstab`</br>
  */swapfile none swap defaults 0 0*
* enable colors in pacman.conf</br>
  `nano /etc/pacman.conf`
  *Color*
* reboot</br>
  `reboot`

# Some packages to install

* login as the non root user</br>
* install some packages</br>
  `sudo pacman -S docker docker-compose openssh sshfs git cronie curl`</br>
  `sudo pacman -S borg zsh vim htop lm_sensors`
* install yay for access to AUR packages</br>
  `git clone https://aur.archlinux.org/yay-bin.git`</br>
  `cd yay-bin && makepkg -si`</br>
  `cd .. && rm -rf yay-bin`</br>

# Setup docker

* have `docker` and `docker-compose` packages installed</br>
  `sudo pacman -S docker docker-compose`
* enable docker service</br>
  `sudo systemctl enable --now docker`
* add non-root user to the docker group</br>
  `sudo gpasswd -a bastard docker`


### Setup SSH access

* have openssh packages installed
  `sudo pacman -S openssh`
* edit sshd_config
  `sudo nano /etc/ssh/sshd_config`</br>
  *change whatever desires*

### ZSH shell

I like [Zim](https://github.com/zimfw/zimfw)

* have zsh package installed
* change users default shell to zsh</br>
  `chsh -s /bin/zsh`
  `curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh`

### ZSH shell



  `arch-chroot /mnt`
* install grub</br>
  `grub-install /dev/sda`</br>
  `grub-mkconfig -o /boot/grub/grub.cfg`
* remove the bootable media and restart the machine</br>
  `exit`</br>
  `reboot`

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>
Bitwarden_rs documentation has a 
[section on reverse proxy.](https://github.com/dani-garcia/bitwarden_rs/wiki/Proxy-examples)

`Caddyfile`
```
passwd.{$MY_DOMAIN} {
    header / {
       X-XSS-Protection "1; mode=block"
       X-Frame-Options "DENY"
       X-Robots-Tag "none"
       -Server
    }
    encode gzip
    reverse_proxy /notifications/hub/negotiate bitwarden:80
    reverse_proxy /notifications/hub bitwarden:3012
    reverse_proxy bitwarden:80
}
```

# Forward port 3012 TCP on your router

[WebSocket](https://youtu.be/2Nt-ZrNP22A) protocol is used for notifications,
so that all web based clients can immediatly sync when a change happens on the server.

* Enviromental variable `WEBSOCKET_ENABLED=true` needs to be set.</br>
* Reverse proxy needs to route `/notifications/hub` to port 3012.</br>
* Router needs to **forward port 3012** to docker host,
same as port 80 and 443 are forwarded.

To test if websocket works, have the desktop app open
and make changes through browser extension, or through the website.
Changes should immediatly appear in the desktop app. If it is not working,
you need to manually sync for changes to appear.
 
# Extra info

**bitwarden can be managed** at `<url>/admin` and entering `ADMIN_TOKEN`
set in the `.env` file. Especially if signups are disabled it is the only way
to invite users.

**push notifications**

---

![interface-pic](https://i.imgur.com/5LxEUsA.png)

# Update

  * [watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower) updates the image automaticly

  * manual image update</br>
    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`

# Backup and restore

  * **backup** using [BorgBackup setup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
  that makes daily snapshot of the entire directory
    
  * **restore**</br>
    down the bitwarden container `docker-compose down`</br>
    delete the entire bitwarden directory</br>
    from the backup copy back the bitwarden directortory</br>
    start the container `docker-compose up -d`

# Backup of just user data

User-data daily export using the [official procedure.](https://github.com/dani-garcia/bitwarden_rs/wiki/Backing-up-your-vault)</br>
For bitwarden_rs it means sqlite database dump and backing up `attachments` directory.</br>

Daily run of [BorgBackup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
takes care of backing up the directory.
So only database dump is needed.
The created backup sqlite3 file is overwriten on every run of the script,
but that's ok since BorgBackup is making daily snapshots.

* **create a backup script**</br>
    placed inside `bitwarden` directory on the host
    
    `bitwarden-backup-script.sh`
    ```
    #!/bin/bash

    # CREATE SQLITE BACKUP
    docker container exec bitwarden sqlite3 /data/db.sqlite3 ".backup '/data/BACKUP.bitwarden.db.sqlite3'"
    ```

    the script must be **executabe** - `chmod +x bitwarden-backup-script.sh`

* **cronjob** on the host</br>
  `crontab -e` - add new cron job</br>
  `0 2 * * * /home/bastard/docker/bitwarden/bitwarden-backup-script.sh` - run it [at 02:00](https://crontab.guru/#0_2_*_*_*)</br>
  `crontab -l` - list cronjobs

# Restore the user data

  Assuming clean start.

  * start the bitwarden container: `docker-compose up -d`
  * let it run so it creates its file structure
  * down the container `docker-compose down`
  * in `bitwarden/bitwarden-data/`</br>
    replace `db.sqlite3` with the backup one `BACKUP.bitwarden.db.sqlite3`</br>
    replace `attachments` directory with the one from the BorgBackup repository 
  * start the container `docker-compose up -d`

