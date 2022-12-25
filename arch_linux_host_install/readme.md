# Arch Linux installation to serve as a docker host

###### guide-by-example

![logo](https://i.imgur.com/SkENpGn.png)

# Notice

**Since 2022 I am using the [archinstall script](https://github.com/archlinux/archinstall)
that comes with arch iso**<br>
**After the install [I use my ansible playbooks](https://github.com/DoTheEvo/ansible-arch) to setup the arch the way I like it**

# Purpose

Linux that will run docker.

This is not a hand holding explaining guide how to install arch.<br>
It's more of a checklist on what to do if you already done it
and know what you are doing.<br>

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

[wiki](https://wiki.archlinux.org/index.php/USB_flash_installation_media)

`sudo dd bs=4M if=archlinux-2020.05.01-x86_64.iso of=/dev/sdX status=progress oflag=direct`

The above command will fuck your machine up if you dunno what you are doing.

# Boot from the usb

This is BIOS/MBR setup as I am running on an old thinkpad with a busted screen,
plus I like the simplicity of it.<br>
So if theres boot menu option choose non-uefi.

# Installation 

* create a single partition and mark it bootable<br>
  `cfdisk -z /dev/sda`
* build ext4 filesystem on it<br>
  `mkfs.ext4 /dev/sda1`
* mount the new partition<br>
  `mount /dev/sda1 /mnt`
* install the base system <br>
  `pacstrap /mnt base linux linux-firmware base-devel grub micro`
* generate fstab<br>
  `genfstab -U /mnt > /mnt/etc/fstab`
* chroot in to the new system<br>
  `arch-chroot /mnt`
* install grub<br>
  `grub-install /dev/sda`<br>
  `grub-mkconfig -o /boot/grub/grub.cfg`
* set password for root<br>
  `passwd`
* remove the bootable media and restart the machine<br>
  `exit`<br>
  `reboot`

# Basic configuration after the first boot

* login as `root`<br>
* set hostname<br>
  `echo docker-host > /etc/hostname`
* add new user and set their password<br>
  `useradd -m -G wheel bastard`<br>
  `passwd bastard`
* edit sudoers to allow users of the group wheel to sudo<br>
  `EDITOR=micro visudo`<br>
  *%wheel ALL=(ALL) ALL*
* check the network interface name<br>
  `ip link`
* setup networking using systemd-networkd and systemd-resolved<br>
  create `20-wired.network` file either in static or dhcp configuration

  `micro /etc/systemd/network/20-wired.network`
  
  ```
  [Match]
  Name=enp0s25

  [Network]
  Address=10.0.19.2/24
  Gateway=10.0.19.1
  #DNS=8.8.8.8
  ```

  ```
  [Match]
  Name=enp0s25

  [Network]
  DHCP=yes
  ```

  for DNS resolution and hostname exposure using mDNS and LLMNR<br>
  `systemd-resolved` will be used in stub mode</br>
  by replacing `/etc/resolv.conf` with a link to `stub-resolv.conf`

  `ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf`

  enable the services
  
  * `systemctl enable --now systemd-resolved`
  * `systemctl enable --now systemd-networkd`

* uncomment desired locales in locale.gen<br>
  `micro /etc/locale.gen`<br>
* generate new locales and set one system wide<br>
  `locale-gen`<br>
  `localectl set-locale LANG=en_US.UTF-8`
* select timezone and set it permanent<br>
  `tzselect`<br>
  `timedatectl set-timezone 'Europe/Bratislava'`
* set hardware clock and sync using ntp<br>
  `hwclock --systohc --utc`<br>
  `timedatectl set-ntp true`
* setup a swap file<br>
  `dd if=/dev/zero of=/swapfile bs=1M count=8192 status=progress`<br>
  `chmod 600 /swapfile`<br>
  `mkswap /swapfile`<br>
  `micro /etc/fstab`<br>
  */swapfile none swap defaults 0 0*
* reboot<br>
  `reboot`

# SSH, Docker, ZSH, AUR

From now on its login as non-root user.

### Setup SSH access

[wiki](https://wiki.archlinux.org/index.php/OpenSSH)

* install openssh package<br>
  `sudo pacman -S openssh`
* edit sshd_config<br>
  `sudo micro /etc/ssh/sshd_config`<br>
  *PasswordAuthentication yes*
* enable sshd service<br>
  `sudo systemctl enable --now sshd`

### Setup docker

[Wiki](https://wiki.archlinux.org/index.php/docker)

* have `docker` and `docker-compose` packages installed<br>
  `sudo pacman -S docker docker-compose`
* enable docker service<br>
  `sudo systemctl enable --now docker`
* add non-root user to the docker group<br>
  `sudo gpasswd -a bastard docker`  

### ZSH shell

[wiki](https://wiki.archlinux.org/index.php/zsh)

I like [Zim](https://github.com/zimfw/zimfw),
it's the fastest zsh framework and set up nicely out of the box

* install zsh and curl packages<br>
  `sudo pacman -S zsh git curl`
* install zim<br>
  `curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh`
* change the default shell to zsh <br>
  `chsh -s /bin/zsh`
* I prefer [steeef](https://github.com/zimfw/steeef) theme
  `echo 'zmodule steeef' >> ~/.zimrc && zimfw install`

##### Adding stuff to .zshrc

`micro .zshrc`

* `export EDITOR=micro`<br>
  `export VISUAL=micro`

* for ctrl+f prepending sudo

  ```bash
  add_sudo (){
      BUFFER="sudo $BUFFER"
      zle -w end-of-line
  }
  zle -N add_sudo
  bindkey "^f" add_sudo
  ```

##### ZSH docker autocomplete

[Here](https://docs.docker.com/compose/completion/#zsh).
For zim it's "Without oh-my-zsh shell" section.

### Access to AUR

Using [Yay](https://github.com/Jguer/yay).

* install git package<br>
  `sudo pacman -S git`
* install yay<br>
  `git clone https://aur.archlinux.org/yay-bin.git`<br>
  `cd yay-bin && makepkg -si`<br>
  `cd .. && rm -rf yay-bin`<br>

`ctop-bin` and `inxi` are good AUR packages.

# Extra stuff

[wiki - general general recommendations](https://wiki.archlinux.org/index.php/general_recommendations)<br>
[wiki - improving performance](https://wiki.archlinux.org/index.php/Improving_performance)<br>

### CPU [microcode](https://wiki.archlinux.org/index.php/Microcode)

* `sudo pacman -S intel-ucode`
* `sudo grub-mkconfig -o /boot/grub/grub.cfg`

### Some packages

Tools 

* `sudo pacman -S fuse curl wget micro nnn bind-tools borg python-llfuse`

Monitoring and testing

* `sudo pacman -S htop lm_sensors iotop nload powertop iproute2`

### Performance and maintenance

* install cron and enable the service<br>
  `sudo pacman -S cronie`<br>
  `sudo systemctl enable --now cronie`
* if ssd, enable periodic trim<br>
  `sudo pacman -S util-linux`<br>
  `sudo systemctl enable --now fstrim.timer`
* set noatime in fstab to prevent unnecessary tracking of read times<br>
  `sudo micro /etc/fstab`<br>
  *UUID=cdd..addb / ext4 rw,noatime 0 1*
* enable use of all cpu cores for makepkg jobs and disable compression<br>
  `sudo micro /etc/makepkg.conf`<br>
  *MAKEFLAGS="-j$(nproc)"*<br>
  *PKGEXT='.pkg.tar'*
* clean up old packages weekly, keep last 3<br>
  `sudo pacman -S pacman-contrib`<br>
  `sudo systemctl enable --now paccache.timer`

* use reflector to get the fastest mirrors based on country `-c <country code>`<br>
  `sudo pacman -S reflector`<br>
  `sudo reflector -c SK,CZ,UA -p http --score 20 --sort rate --save /etc/pacman.d/mirrorlist`

  automatic mirror update with reflector

  `/etc/xdg/reflector/reflector.conf`
  ```
  --save /etc/pacman.d/mirrorlist
  --protocol http
  --country SK,CZ,UA
  --score 20
  --sort rate
  ```

  enable it, it will run weekly

  `sudo systemctl enable --now reflector.timer`

### Comfort

* enable colors in pacman.conf<br>
  `sudo micro /etc/pacman.conf`<br>
  *Color*

### Notebook

Lid closed should not make the machine go to sleep.

* Set lid handle switch to ignore in systemd logind.conf<br>
  `sudo micro /etc/systemd/logind.conf`<br>
  *HandleLidSwitch=ignore*

**But this alone leaves the screen running nonstop.**

Tried to find solution, and while `sudo vbetool dpms off` works,
turning it back on does not `sudo vbetool dpms on` and it timesout without
any message or error.

Might be specific for the hardware, currently its latitude E5570
